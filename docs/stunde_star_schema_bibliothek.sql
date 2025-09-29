-- Safe drop in dependency order: FACT first, then mappings, then dimensions, then sequence
BEGIN EXECUTE IMMEDIATE 'DROP TABLE FACT_LEND'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE PATRON_DIM_ID'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE LIBRARY_DIM_ID'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE DIM_LIBRARY'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE DIM_BOOK'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE DIM_TIME'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE DIM_PATRON'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE DIM_SEQ'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Dimensionstabellen:
CREATE TABLE DIM_BOOK(ID NUMBER PRIMARY KEY, TITLE VARCHAR(32) NOT NULL, RATING NUMBER, author VARCHAR(32));
CREATE TABLE DIM_TIME(id NUMBER PRIMARY KEY, year NUMBER, month NUMBER, day NUMBER);
CREATE TABLE DIM_PATRON(id NUMBER PRIMARY KEY, LAST_NAME VARCHAR(32), CITY VARCHAR(32) NOT NULL, STATE VARCHAR(32) NOT NULL);

-- FACT_LEND wird erst später erzeugt (nachdem DIM_LIBRARY existiert) – siehe sql/03_fact_lend_load.sql

CREATE SEQUENCE DIM_SEQ START WITH 1;

-- Befuellen der Dimensionen:
INSERT INTO DIM_BOOK (SELECT dim_seq.nextval, b.title, b.rating, a.last_name FROM BOOKS b JOIN AUTHORS a ON (b.author_id = a.author_id));

-- Zeitdimension ist etwas "speziell":
-- * Ueblicherweise findet keine Denormalisierung (=joins) statt, es wird nur der Datumwert in seine Komponenten aufgespalten
-- * Zeiten koennen mehrfach vorkommen (z.B. zwei Events um die selbe Zeit), dies ist bei den normalisierten Ausgangsdaten der anderen Dimensionen nicht der Fall
--  -> beide Events sollen aber auf den selben Eintrag in der Dimensionstabelle verweisen - daher DISTINCT
INSERT INTO DIM_TIME (SELECT dim_seq.nextval, t.* FROM 
                            (SELECT DISTINCT EXTRACT(year FROM transaction_date), 
                                             EXTRACT(month FROM transaction_date), 
                                             EXTRACT(day FROM transaction_date) FROM TRANSACTIONS) t);



-- Aufloesen der Dimensions-FKs (Foreign Keys) fuer das Befuellen der FACT-Table ist auf zwei Arten moeglich
-- a.) Vergleich aller Werte der Eingangsdaten mit der jeweiligen Dimension -> liefert den entsprechenden Primary Key der Dimension
SELECT (SELECT td.id FROM DIM_TIME td WHERE EXTRACT(year FROM transaction_date)=td.year AND 
                                            EXTRACT(month FROM transaction_date)=td.month AND 
                                            EXTRACT(day FROM transaction_date)=td.day) AS dim_time_id, t.costs, t.duration FROM TRANSACTIONS t;

-- am Beispiel des FKs der BOOK-Dimension:
SELECT (SELECT db.id FROM DIM_BOOK db WHERE db.title=b.title AND db.author=a.last_name) AS dim_book_id, t.costs, t.duration FROM TRANSACTIONS t JOIN BOOKS b ON (b.book_id = t.book_id) JOIN AUTHORS a ON (a.author_id = b.author_id);



-- b.) Temporaere Tabelle, welche die Zuordnung ID der Input-Daten zu ID der Dimension enthält.
-- z.B: 
-- Erstellen einer temporaeren Tabelle, welche exakt wie die eigentliche Dimensionstabelle aussieht + die "alte" ID der Ausgangsdaten beinhaltet:
CREATE TABLE PATRON_DIM_ID AS (
  SELECT dim_seq.nextval AS id_dim,
         p.patron_id     AS id_alt,
         p.last_name,
         l.city,
         l.state
    FROM PATRONS p
    JOIN locations l ON (p.location_id = l.location_id)
);
-- Daraus dann die eigentliche Dimensionstabelle erzeugen:
INSERT INTO DIM_PATRON (id, last_name, city, state)
SELECT id_dim, last_name, city, state
FROM PATRON_DIM_ID;

-- beim Aufloesen der Dimensions-ID kann dann einfach in dieser Tabelle nachgeschlagen werden.
SELECT (SELECT pd.id_dim FROM PATRON_DIM_ID pd WHERE pd.id_alt = t.patron_id) as dim_patron_id, t.costs, t.duration FROM TRANSACTIONS t;


-- Aufbau des Inhalts der Fact-Tabelle
-- 1. Primary-Key: Alle Foreign-Keys der Dimensionen, falls Duplikate möglich -> synthetischer Primary Key
-- 2. die Foreign-Keys, die auf die jeweiligen Dimensionen verweisen
-- 3. die Measures / numerischen Werte

COMMIT;
/