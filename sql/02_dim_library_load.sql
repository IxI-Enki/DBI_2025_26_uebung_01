--
-- 02_dim_library_load.sql
-- Aufgabe 2: Dimension DIM_LIBRARY mit Werten befüllen
--
-- Kontext:
--   Wir denormalisieren die Bibliothek inkl. ihres Standortes (CITY/STATE/ZIP_CODE)
--   aus den OLTP-Tabellen LIBRARY und LOCATIONS in die Dimension DIM_LIBRARY.
--
-- Voraussetzungen:
--   - DIM_LIBRARY (DDL) und DIM_LIBRARY_SEQ existieren (siehe 01_dim_library_ddl.sql)
--   - OLTP-Tabellen sind geladen (siehe sql/init_schema_library.sql)
--

-- Doppelte Ausführung vermeiden: Lösche bestehende Einträge (idempotent).
DELETE FROM DIM_LIBRARY;
COMMIT;

-- Einfügen der Dimensionseinträge per INSERT-SELECT.
--   Für jede Bibliothek wird ein Surrogat-Schlüssel aus der Sequenz vergeben,
--   die restlichen Attribute stammen aus LIBRARY und der verknüpften LOCATIONS-Zeile.
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

-- Validierung (optional): Anzahl geladener Bibliotheken anzeigen
-- SELECT COUNT(*) AS dim_library_count FROM DIM_LIBRARY;
