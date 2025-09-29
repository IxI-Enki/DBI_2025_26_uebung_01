--
-- 01_dim_library_ddl.sql
-- Aufgabe 1: Dimension DIM_LIBRARY definieren (DDL)
--
-- Kontext:
--   Basierend auf dem OLTP-Schema (TABLES: LIBRARY, LOCATIONS, AUTHORS, BOOKS, PATRONS, TRANSACTIONS)
--   soll für das Star-Schema eine Bibliotheks-Dimension aufgebaut werden.
--   Diese Dimension denormalisiert Name und Ortsangaben der Bibliothek.
--
-- WICHTIG:
--   Dieses Skript legt lediglich die DDL (Tabellenstruktur + Sequenz) an.
--   Das Befüllen erfolgt in 02_dim_library_load.sql.
--

-- Vorsorglich alte Objekte entfernen (falls vorhanden)
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE DIM_LIBRARY';
EXCEPTION WHEN OTHERS THEN NULL; -- Tabelle existierte evtl. noch nicht
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP SEQUENCE DIM_LIBRARY_SEQ';
EXCEPTION WHEN OTHERS THEN NULL; -- Sequenz existierte evtl. noch nicht
END;
/

--
-- Dimensionstabelle: DIM_LIBRARY
--   Surrogat-Schlüssel: ID (NUMBER)
--   Attribute: LIBRARY_NAME, CITY, STATE, ZIP_CODE
--   Unique-Constraint stellt sicher, dass die Kombination aus Name + Ort eindeutig ist
--
CREATE TABLE DIM_LIBRARY (
  ID            NUMBER       PRIMARY KEY,
  LIBRARY_NAME  VARCHAR2(30) NOT NULL,
  CITY          VARCHAR2(30) NOT NULL,
  STATE         VARCHAR2(30) NOT NULL,
  ZIP_CODE      VARCHAR2(10) NOT NULL,
  CONSTRAINT UQ_DIM_LIBRARY UNIQUE (LIBRARY_NAME, CITY, STATE, ZIP_CODE)
);
/

-- Sequenz für Surrogat-Schlüssel der Dimension
CREATE SEQUENCE DIM_LIBRARY_SEQ START WITH 1 INCREMENT BY 1 NOCACHE;
/

-- Hinweis:
--  Weitere Dimensionen (DIM_BOOK, DIM_TIME, DIM_PATRON) sowie FACT_LEND
--  sind im Unterrichtsskript (docs/stunde_star_schema_bibliothek.sql) definiert.
