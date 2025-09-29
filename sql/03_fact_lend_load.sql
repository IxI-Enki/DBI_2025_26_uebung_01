--
-- 03_fact_lend_load.sql
-- Aufgabe 3: FACT_LEND mit robusten Joins befüllen (vermeidet ORA-01427)
--
-- Kontext:
--   Wir befüllen die Faktentabelle FACT_LEND aus TRANSACTIONS.
--   Zur FK-Auflösung verwenden wir Mappingtabellen und CTEs mit Aggregation,
--   damit pro Geschäftsschlüssel genau EIN Dimensionsschlüssel bestimmt wird.
--   Das vermeidet Fehler wie ORA-01427 (mehr als eine Zeile in einer Skalar-Subquery).
--
-- Voraussetzungen:
--   - DIM_TIME, DIM_BOOK, DIM_PATRON existieren und sind befüllt (vgl. Unterrichtsskript)
--   - DIM_LIBRARY existiert und ist befüllt (siehe 01_ und 02_-Skripte)
--   - FACT_LEND wird bei Bedarf in diesem Skript erstellt
--

-- Sicherstellen, dass FACT_LEND existiert (erst nach vorhandenen Dimensionen)
DECLARE
  v_exists   NUMBER;
  v_attempts NUMBER := 0;
BEGIN
  LOOP
    SELECT COUNT(*) INTO v_exists FROM user_tables WHERE table_name = 'FACT_LEND';
    IF v_exists = 0 THEN
      BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE FACT_LEND(
          t      NUMBER REFERENCES DIM_TIME(id),
          lib    NUMBER REFERENCES DIM_LIBRARY(id),
          book   NUMBER REFERENCES DIM_BOOK(id),
          patron NUMBER REFERENCES DIM_PATRON(id),
          costs  NUMBER,
          duration NUMBER,
          PRIMARY KEY(t, lib, book, patron)
        )';
        EXIT;
      EXCEPTION
        WHEN OTHERS THEN
          IF SQLCODE = -955 THEN
            EXIT; -- already exists
          ELSIF SQLCODE = -54 THEN
            v_attempts := v_attempts + 1;
            IF v_attempts < 5 THEN
              DBMS_LOCK.SLEEP(0.5);
            ELSE
              RAISE;
            END IF;
          ELSE
            RAISE;
          END IF;
      END;
    ELSE
      EXIT;
    END IF;
  END LOOP;
END;
/

-- Hilfstabelle: Zuordnung PATRON (OLTP-ID) -> DIM_PATRON.ID
--   Wir bauen die Mappingtabelle über Übereinstimmung von LAST_NAME, CITY, STATE auf.
--   (Diese Werte wurden so auch in DIM_PATRON übernommen.)
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE PATRON_DIM_ID';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Wähle deterministisch genau EIN Dimensionsschlüssel je Patron (falls Duplikate existieren: MIN(id))
CREATE TABLE PATRON_DIM_ID AS
SELECT
  p.patron_id                 AS id_alt,
  MIN(dp.id)                  AS id_dim
FROM PATRONS p
JOIN LOCATIONS l ON l.location_id = p.location_id
JOIN DIM_PATRON dp
  ON dp.last_name = p.last_name
 AND dp.city      = l.city
 AND dp.state     = l.state
GROUP BY p.patron_id;


-- Hilfstabelle: Zuordnung LIBRARY (OLTP-ID) -> DIM_LIBRARY.ID
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE LIBRARY_DIM_ID';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Wähle deterministisch genau EIN Dimensionsschlüssel je Library (MIN(id) pro library_id)
CREATE TABLE LIBRARY_DIM_ID AS
SELECT
  lib.library_id             AS id_alt,
  MIN(dl.id)                 AS id_dim
FROM LIBRARY lib
JOIN LOCATIONS loc ON loc.location_id = lib.location_id
JOIN DIM_LIBRARY dl
  ON dl.LIBRARY_NAME = lib.name
 AND dl.CITY         = loc.city
 AND dl.STATE        = loc.state
 AND dl.ZIP_CODE     = loc.zip_code
GROUP BY lib.library_id;

-- Idempotenz: FACT_LEND leeren, damit das Skript mehrfach ausführbar ist
BEGIN
  EXECUTE IMMEDIATE 'DELETE FROM FACT_LEND';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
COMMIT;
/

--
-- Befüllung FACT_LEND
--   Für jede Zeile aus TRANSACTIONS ermitteln wir:
--     t    -> DIM_TIME.ID anhand year/month/day der TRANSACTION_DATE
--     lib  -> DIM_LIBRARY.ID per Mappingtabelle LIBRARY_DIM_ID
--     book -> DIM_BOOK.ID über Titel + Autor (Nachname)
--     patron -> DIM_PATRON.ID per Mappingtabelle PATRON_DIM_ID
--     costs, duration -> direkt aus TRANSACTIONS
--
-- Kein WITH-CTE (Kompatibilität zu Tools): nutze Inline-Subqueries
INSERT INTO FACT_LEND (t, lib, book, patron, costs, duration)
SELECT
  tm.id                      AS t,
  ldm.id_dim                 AS lib,
  bm.id                      AS book,
  pd.id_dim                  AS patron,
  tr.costs,
  tr.duration
FROM TRANSACTIONS tr
JOIN BOOKS b    ON b.book_id   = tr.book_id
JOIN AUTHORS a  ON a.author_id = b.author_id
JOIN (
  SELECT year, month, day, MIN(id) AS id
  FROM DIM_TIME
  GROUP BY year, month, day
) tm
  ON tm.year  = EXTRACT(YEAR  FROM tr.transaction_date)
 AND tm.month = EXTRACT(MONTH FROM tr.transaction_date)
 AND tm.day   = EXTRACT(DAY   FROM tr.transaction_date)
JOIN LIBRARY_DIM_ID ldm ON ldm.id_alt = tr.library_id
JOIN PATRON_DIM_ID  pd  ON pd.id_alt  = tr.patron_id
JOIN (
  SELECT title, author, MIN(id) AS id
  FROM DIM_BOOK
  GROUP BY title, author
) bm
  ON bm.title  = b.title
 AND bm.author = a.last_name;

COMMIT;
/

-- Optionale Kontrolle: Anzahl Faktzeilen
-- SELECT COUNT(*) AS fact_lend_count FROM FACT_LEND;
