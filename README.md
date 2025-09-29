---
title: "DBI Übung 01 – Star-Schema Bibliothek"
exercise_name: "Star-Schema Bibliothek"
exercise_number: 1
created: "2025-09-25"
author: "Jan Ritt"
course: "Datenbanken und Informationssysteme (DBI)"
school_year: "2025/26"
moodle_link: "https://edufs.edu.htl-leonding.ac.at/moodle/mod/assign/view.php?id=213382"
due_date: "2025-09-30-00:00"
---

In dieser Übung modellieren Sie ein Star-Schema für eine Bibliothek,
erstellen Dimensionen und Faktentabellen und leiten Analyseabfragen ab.

## Aufgabenüberblick

| Angabe:   |
| :-------- |
| 🌐 Link zur [Aufgabe auf Moodle](https://edufs.edu.htl-leonding.ac.at/moodle/mod/assign/view.php?id=213382) |
| 📄Fetched [`angabe/moodle_angabe.md`](angabe/moodle_angabe.md) |

> ## *Star-Schema Bibliothek*
>
> > **Geöffnet**: Mittwoch, 17. September 2025, 00:00
> > **Fällig**: Dienstag, 30. September 2025, 00:00
>
> > Überführen Sie das gegebene OLTP-Schema in ein Star-Schema.
> >
> > 1. Ergänzen Sie den Code der Stunde um die Bibliotheks-Dimension DIM_LIBRARY
> >
> > 2. Befüllen Sie diese Dimension mit Werten
> >
> > 3. Befüllen Sie die Faktentabelle FACT_LEND, indem Sie mittels SubQuery
> >    zu jeder Dimension den passenden Foreign-Key finden, sowie Primary-Key & Measures ergänzen.
> >
> > *Nutzen Sie dabei die bereits in der Stunde ausgearbeiteten Statements als Ausgangsbasis*:
> >
> > **↳** [📄 `stunde_star_schema_bibliothek.sql`](docs/stunde_star_schema_bibliothek.sql)
> > **↳** [📄 `library_schema.sql`](angabe/library_schema.sql)  <!--17. September 2025, 16:39-->
>

---

## Entity-Relation-Diagramm der initialen Bibliothek

```mermaid
<generate>
```

---

## Abgabehinweise

- Diagramme als Bild/Markdown einbinden
- Abgabe als Git-Repository mit sauberer Historie

  ### Git-Workflow (Empfehlung)
  
  - `main` stabil halten; Feature-Branches für Teilaufgaben
  - Aussagekräftige Commits in kleinen Schritten

  ### Struktur

  - `angaben/` Aufgabenstellung/Material
  - `docs/` Relevante Dokumente aus dem Unterricht
  - `sql/` Optional DDL/Abfragen
