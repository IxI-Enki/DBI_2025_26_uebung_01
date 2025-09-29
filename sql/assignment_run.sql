----------------------------------------------------------------------------------------------------
-- Assignment: STAR SCHEMA LIBRARY
-- DBI - Datenbanken und Informationssysteme
-- HTL Leonding
-- Ritt Jan
-- 2025-09-29
----------------------------------------------------------------------------------------------------

-- 1. Ergänzen Sie den Code der Stunde um die Bibliotheks-Dimension DIM_LIBRARY
--
-- 2. Befüllen Sie diese Dimension mit Werten
--
-- 3. Befüllen Sie die Faktentabelle FACT_LEND, indem Sie mittels SubQuery
--    zu jeder Dimension den passenden Foreign-Key finden, sowie Primary-Key & Measures ergänzen.

----------------------------------------------------------------------------------------------------

-- 1. Dimension DIM_LIBRARY definieren (DDL)

-- Vorsorglich alte Objekte entfernen (falls vorhanden)
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE DIM_LIBRARY';
EXCEPTION WHEN OTHERS THEN NULL; -- Tabelle existierte evtl. noch nicht
END;

BEGIN
  EXECUTE IMMEDIATE 'DROP SEQUENCE DIM_LIBRARY_SEQ';
EXCEPTION WHEN OTHERS THEN NULL; -- Sequenz existierte evtl. noch nicht
END;

-----

CREATE TABLE DIM_LIBRARY (
  ID            NUMBER       PRIMARY KEY,
  LIBRARY_NAME  VARCHAR2(30) NOT NULL,
  CITY          VARCHAR2(30) NOT NULL,
  STATE         VARCHAR2(30) NOT NULL,
  ZIP_CODE      VARCHAR2(10) NOT NULL,
  CONSTRAINT UQ_DIM_LIBRARY UNIQUE (LIBRARY_NAME, CITY, STATE, ZIP_CODE)
);

-- Sequenz für Surrogat-Schlüssel der Dimension
CREATE SEQUENCE DIM_LIBRARY_SEQ START WITH 1 INCREMENT BY 1 NOCACHE;

----------------------------------------------------------------------------------------------------

-- 2. Dimension DIM_LIBRARY mit Werten befüllen

-- Doppelte Ausführung vermeiden: Lösche bestehende Einträge (idempotent).
DELETE FROM DIM_LIBRARY;
COMMIT;

INSERT INTO DIM_LIBRARY (ID, LIBRARY_NAME, CITY, STATE, ZIP_CODE)
SELECT
  DIM_LIBRARY_SEQ.NEXTVAL   AS ID,
  l.name                    AS LIBRARY_NAME,
  loc.city                  AS CITY,
  loc.state                 AS STATE,
  loc.zip_code              AS ZIP_CODE
FROM LIBRARY l
JOIN LOCATIONS loc ON loc.location_id = l.location_id;

COMMIT;

----------------------------------------------------------------------------------------------------

-- 3. FACT_LEND mit robusten Joins befüllen

-- Alte Objekte entfernen (falls vorhanden)
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

-- Befüllung FACT_LEND
--   Für jede Zeile aus TRANSACTIONS ermitteln wir:
--     t    -> DIM_TIME.ID anhand year/month/day der TRANSACTION_DATE
--     lib  -> DIM_LIBRARY.ID per Mappingtabelle LIBRARY_DIM_ID
--     book -> DIM_BOOK.ID über Titel + Autor (Nachname)
--     patron -> DIM_PATRON.ID per Mappingtabelle PATRON_DIM_ID
--     costs, duration -> direkt aus TRANSACTIONS
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
