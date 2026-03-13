# Oppgave 2: SQL-spørringer og databaseskjema

## Læringsmål

Etter å ha fullført denne oppgaven skal du:
- Forstå relasjonsdatabaseskjemaet
- Skrive SELECT-spørringer med WHERE, JOIN, ORDER BY
- Bruke aggregatfunksjoner (COUNT, AVG, SUM)
- Forstå primærnøkler, fremmednøkler og integritetskontroller
- Kunne lese og tolke databasediagrammer

## Bakgrunn

En relasjonsdatabase er organisert i **tabeller** som består av **rader** og **kolonner**. Tabeller er knyttet sammen 
gjennom **fremmednøkler**.

**Databaseskjemaet for DATA1500:**

```
programmer (program_id, program_navn, beskrivelse, opprettet)                                         
studenter (student_id, fornavn, etternavn, epost, program_id, opprettet)              
emneregistreringer (registrering_id, student_id, emne_id, semester, karakter, registrert_dato)
emner (emne_id, emne_kode, emne_navn, studiepoeng, beskrivelse, opprettet)
```

**Nøkkelbegreper:**
- **Primærnøkkel (PK):** Unik identifikator for hver rad (f.eks. `student_id`)
- **Fremmednøkkel (FK):** Referanse til primærnøkkel i en annen tabell
- **Integritetskontroll:** Regler som sikrer datakonsistens (f.eks. `CHECK (studiepoeng > 0)`)

## Oppgave

Alle spørringene skal kjøres i PostgreSQL. Du kan bruke `psql` (klienten for postgres-serveren) eller et GUI-verktøy som 
pgAdmin eller DBeaver. **Anbefalt** å bruke `psql` først og så gå over til GUI-verktøy.

For å bruke `psql` kan du "logge inn" i container og i psql-shell med følgende kommandoer:
```bash
    $ docker-compose up 
    $ docker-compose exec postgres psql -U admin -d data1500_db
```

Forventet output er en psql-shell:
```bash
    psql (15.15)
    Type "help" for help.

    data1500_db=#
```

Utforsk "help". I `psql` finnes det egne kommandoer (ikke SQL-basert) for å få ut metadata om database. For eksempel, 
vil kommandoen `\d` liste ut alle tabeller, views og sekvenser i den gjeldende databasen `data1500_db`.

### Del 1: Grunnleggende SELECT-spørringer

**1.1** Hent alle studenter med fornavn, etternavn og epost:

```sql
SELECT fornavn, etternavn, epost FROM studenter;
```
Viser:
fornavn | etternavn |              epost
---------+-----------+----------------------------------
Ola     | Nordmann  | ola.nordmann@student.oslomet.no
Kari    | Normann   | kari.normann@student.oslomet.no
Per     | Larsen    | per.larsen@student.oslomet.no
Anna    | Johansen  | anna.johansen@student.oslomet.no
(4 rows)

**1.2** Hent alle emner sortert etter emne_navn:

```sql
SELECT emne_kode, emne_navn, studiepoeng FROM emner ORDER BY emne_navn;
```
Viser:
emne_kode |       emne_navn       | studiepoeng
-----------+-----------------------+-------------
DATA1500  | Databaser             |          10
DATA2200  | Databasesystemer      |          10
DATA3100  | Distribuerte systemer |          10
DATA1100  | Programmering         |          10
(4 rows)

**1.3** Hent alle studenter fra Informatikk-programmet (program_id = 1):

```sql
SELECT fornavn, etternavn, epost FROM studenter WHERE program_id = 1;
```
Viser:
fornavn | etternavn |              epost
---------+-----------+---------------------------------
Ola     | Nordmann  | ola.nordmann@student.oslomet.no
Kari    | Normann   | kari.normann@student.oslomet.no
(2 rows)

### Del 2: JOIN-spørringer

**2.1** Hent alle studenter med deres program:

```sql
SELECT 
    s.fornavn, 
    s.etternavn, 
    p.program_navn
FROM studenter s
LEFT JOIN programmer p ON s.program_id = p.program_id;
```
Viser:
fornavn | etternavn |  program_navn
---------+-----------+----------------
Kari    | Normann   | Informatikk
Ola     | Nordmann  | Informatikk
Per     | Larsen    | Data Science
Anna    | Johansen  | Cybersikkerhet
(4 rows)

**2.2** Hent alle emneregistreringer med studentnavn og emnenavn:

```sql
SELECT 
    s.fornavn,
    s.etternavn,
    e.emne_navn,
    er.karakter,
    er.semester
FROM emneregistreringer er
JOIN studenter s ON er.student_id = s.student_id
JOIN emner e ON er.emne_id = e.emne_id
ORDER BY s.etternavn, e.emne_navn;
```
Viser:
fornavn | etternavn |       emne_navn       | karakter | semester
---------+-----------+-----------------------+----------+----------
Anna    | Johansen  | Distribuerte systemer | C        | 2024H
Per     | Larsen    | Databasesystemer      | A        | 2024H
Ola     | Nordmann  | Databaser             | A        | 2024H
Ola     | Nordmann  | Programmering         | B        | 2024H
Kari    | Normann   | Databaser             | B        | 2024H
(5 rows)

**2.3** Hent alle emner som DATA1500-studenter er registrert på:

```sql
SELECT DISTINCT e.emne_kode, e.emne_navn
FROM emneregistreringer er
JOIN emner e ON er.emne_id = e.emne_id
WHERE er.student_id IN (
    SELECT student_id FROM studenter WHERE program_id = 1
);
```
Viser:
emne_kode |   emne_navn
-----------+---------------
DATA1100  | Programmering
DATA1500  | Databaser
(2 rows)

### Del 3: Aggregatfunksjoner

**3.1** Tell antall studenter per program:

```sql
SELECT 
    p.program_navn,
    COUNT(s.student_id) as antall_studenter
FROM programmer p
LEFT JOIN studenter s ON p.program_id = s.program_id
GROUP BY p.program_id, p.program_navn
ORDER BY antall_studenter DESC;
```
Viser:
program_navn  | antall_studenter
----------------+------------------
Informatikk    |                2
Data Science   |                1
Cybersikkerhet |                1
(3 rows)

**3.2** Hent gjennomsnittlig karakter per emne:

```sql
SELECT 
    e.emne_navn,
    AVG(CAST(SUBSTRING(er.karakter, 1, 1) AS INT)) as gjennomsnitt
FROM emneregistreringer er
JOIN emner e ON er.emne_id = e.emne_id
WHERE er.karakter IS NOT NULL
GROUP BY e.emne_id, e.emne_navn;
```
```brukte denne sql-spørringen istedet, ettersom karakterer er lagret som bokstaver (A-F)
SELECT 
    e.emne_navn,
    ROUND(AVG(CASE 
        WHEN er.karakter = 'A' THEN 5
        WHEN er.karakter = 'B' THEN 4
        WHEN er.karakter = 'C' THEN 3
        WHEN er.karakter = 'D' THEN 2
        WHEN er.karakter = 'E' THEN 1
        WHEN er.karakter = 'F' THEN 0
    END), 1) as gjennomsnitt
FROM emneregistreringer er
JOIN emner e ON er.emne_id = e.emne_id
WHERE er.karakter IS NOT NULL
GROUP BY e.emne_id, e.emne_navn;
```
Viser:
emne_navn             | gjennomsnitt
-----------------------+--------------
Databaser             |          4.5
Programmering         |          4.0
Databasesystemer      |          5.0
Distribuerte systemer |          3.0
(4 rows)

**3.3** Hent studenter som har flere enn 1 emneregistrering:

```sql
SELECT 
    s.fornavn,
    s.etternavn,
    COUNT(er.registrering_id) as antall_emner
FROM studenter s
LEFT JOIN emneregistreringer er ON s.student_id = er.student_id
GROUP BY s.student_id, s.fornavn, s.etternavn
HAVING COUNT(er.registrering_id) > 1
ORDER BY antall_emner DESC;
```
Viser:
fornavn | etternavn | antall_emner
---------+-----------+--------------
Ola     | Nordmann  |            2
(1 row)

### Del 4: Databaseskjema-analyse

**4.1** Hent alle fremmednøkler i databasen:

```sql
SELECT 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY';
```
Viser:
table_name         | column_name | foreign_table_name | foreign_column_name
-------------------+-------------+--------------------+---------------------
studenter          | program_id  | programmer         | program_id
emneregistreringer | student_id  | studenter          | student_id
emneregistreringer | emne_id     | emner              | emne_id
(3 rows)

**4.2** Hent alle indekser:

```sql
SELECT 
    schemaname,
    tablename,
    indexname
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```
Viser:
schemaname |     tablename      |                     indexname
------------+--------------------+----------------------------------------------------
public     | emner              | emner_emne_kode_key
public     | emner              | emner_pkey
public     | emneregistreringer | emneregistreringer_pkey
public     | emneregistreringer | emneregistreringer_student_id_emne_id_semester_key
public     | emneregistreringer | idx_emneregistreringer_emne
public     | emneregistreringer | idx_emneregistreringer_student
public     | programmer         | programmer_pkey
public     | programmer         | programmer_program_navn_key
public     | studenter          | idx_studenter_program
public     | studenter          | studenter_epost_key
public     | studenter          | studenter_pkey
(11 rows)

## Oppgaver du skal løse

Skriv SQL-spørringer som besvarer følgende spørsmål:

1. **Hent alle studenter som ikke har noen emneregistreringer**
2. **Hent alle emner som ingen studenter er registrert på**
3. **Hent studentene med høyeste karakter per emne**
4. **Lag en rapport som viser hver student, deres program, og antall emner de er registrert på**
5. **Hent alle studenter som er registrert på både DATA1500 og DATA1100**

**Viktig:** Lagre alle spørringene dine i en fil `oppgave2_losning.sql` i mappen `test-scripts` for at man kan teste 
disse med kommando:

```bash
docker-compose exec postgres psql -U admin -d data1500_db -f test-scripts/oppgave2_losning.sql
```

Du kan selv bruke denne kommandoen for å teste dine SQL-spørringer og SQL-setnigner. 

## Refleksjonsspørsmål

Besvar refleksjonsspørsmål i filen **besvarelse-refleksjon.md**


## Avslutning

Når du er ferdig:
- Du forstår (overfladisk) relasjonsdatabaseskjemaet
- Du kan skrive noen SELECT-spørringer (forventes ikke en detaljert kunnskap nå)
- Du er klar for oppgave 3 (brukeradministrasjon)
