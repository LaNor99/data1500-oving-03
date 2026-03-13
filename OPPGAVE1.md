# Oppgave 1: Docker-oppsett og PostgreSQL-tilkobling

## Læringsmål

Etter å ha fullført denne oppgaven skal du:
- Forstå hva Docker er og hvorfor det brukes
- Installere Docker Desktop på din maskin
- Kjøre PostgreSQL i en Docker-container
- Koble til PostgreSQL-databasen med `psql`
- Verifisere at databasen er initialisert med testdata

## Bakgrunn

**Docker** er en virtualiseringplattform som gjør det mulig å pakke applikasjoner og deres avhengigheter i isolerte enheter kalt **containere**. En container inneholder alt som trengs for å kjøre en applikasjon - operativsystem, biblioteker, og kode.

**Fordeler med Docker:**
- Samme miljø på alle maskiner (macOS, Windows, Linux)
- Enkelt å dele og reprodusere miljøer
- Isolering - flere applikasjoner kan kjøre uten konflikter
- Lett å starte/stoppe/slette

**docker-compose** er et verktøy som lar deg definere og kjøre flere Docker-containere med en enkelt kommando.

## Oppgave

### Del 1: Installer Docker Desktop

Følg veiledningen i `DOCKER_INSTALLASJON.md` for din operativsystem:
- **macOS:** Apple Silicon eller Intel
- **Windows:** WSL 2
- **Linux:** Docker og docker-compose

Verifiser at Docker er installert:
```bash
docker --version
```

### Del 2: Start PostgreSQL med docker-compose

I mappen `data1500-oving-03` kjør:

```bash
docker-compose up -d
```

Verifiser at containeren kjører:

```bash
docker-compose ps
```

Du skal se:
```
NAME                  STATUS
data1500-postgres     Up (healthy)
```

### Del 3: Koble til PostgreSQL

Åpne en terminal og kjør:

```bash
docker-compose exec postgres psql -U admin -d data1500_db
```

Passord: `admin123` (ikke nødvendig siden bruker postgres)

Du skal nå være i PostgreSQL-prompten (`data1500_db=#`).

### Del 4: Verifiser initialisering

Kjør følgende SQL-spørringer for å verifisere at databasen er initialisert:

```sql
-- Vis alle tabeller
\dt
- Viser:
List of relations
 Schema |        Name        | Type  | Owner
--------+--------------------+-------+-------
 public | emner              | table | admin
 public | emneregistreringer | table | admin
 public | programmer         | table | admin
 public | studenter          | table | admin
(4 rows)

-- Tell antall programmer
SELECT COUNT(*) as antall_programmer FROM programmer;
- 3programmer

-- Tell antall studenter
SELECT COUNT(*) as antall_studenter FROM studenter;
- 4studenter

-- Tell antall emner
SELECT COUNT(*) as antall_emner FROM emner;
- 4emner

-- Vis alle roller
SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';
Viser:
rolname
----------------
admin
 admin_role
 foreleser_role
 student_role
(4 rows)
```

### Del 5: Utforsk databasen

Kjør disse spørringene for å bli kjent med datastrukturen:

```sql
-- Vis alle programmer
SELECT * FROM programmer;
Viser:
 program_id |  program_navn  |        beskrivelse        |         opprettet
------------+----------------+---------------------------+----------------------------
          1 | Informatikk    | Bachelor i Informatikk    | 2026-03-12 03:16:49.623073
          2 | Data Science   | Bachelor i Data Science   | 2026-03-12 03:16:49.623073
          3 | Cybersikkerhet | Bachelor i Cybersikkerhet | 2026-03-12 03:16:49.623073
(3 rows)

-- Vis alle studenter
SELECT * FROM studenter;
Viser:
student_id | fornavn | etternavn |              epost               | program_id |         opprettet
------------+---------+-----------+----------------------------------+------------+---------------------------
          1 | Ola     | Nordmann  | ola.nordmann@student.oslomet.no  |          1 | 2026-03-12 03:16:49.62627
          2 | Kari    | Normann   | kari.normann@student.oslomet.no  |          1 | 2026-03-12 03:16:49.62627
          3 | Per     | Larsen    | per.larsen@student.oslomet.no    |          2 | 2026-03-12 03:16:49.62627
          4 | Anna    | Johansen  | anna.johansen@student.oslomet.no |          3 | 2026-03-12 03:16:49.62627
(4 rows)

-- Vis alle emner
SELECT * FROM emner;
Viser:
emne_id | emne_kode |       emne_navn       | studiepoeng |            beskrivelse            |         opprettet      
---------+-----------+-----------------------+-------------+-----------------------------------+----------------------------
       1 | DATA1500  | Databaser             |          10 | Introduksjon til databaser og SQL | 2026-03-12 03:16:49.624784
       2 | DATA1100  | Programmering         |          10 | Introduksjon til programmering    | 2026-03-12 03:16:49.624784
       3 | DATA2200  | Databasesystemer      |          10 | Avanserte databasekonsepter       | 2026-03-12 03:16:49.624784
       4 | DATA3100  | Distribuerte systemer |          10 | Distribuerte databasesystemer     | 2026-03-12 03:16:49.624784
(4 rows)

-- Vis emneregistreringer
SELECT * FROM emneregistreringer;
Viser:
registrering_id | student_id | emne_id | semester | karakter |      registrert_dato
-----------------+------------+---------+----------+----------+----------------------------
               1 |          1 |       1 | 2024H    | A        | 2026-03-12 03:16:49.628207
               2 |          1 |       2 | 2024H    | B        | 2026-03-12 03:16:49.628207
               3 |          2 |       1 | 2024H    | B        | 2026-03-12 03:16:49.628207
               4 |          3 |       3 | 2024H    | A        | 2026-03-12 03:16:49.628207
               5 |          4 |       4 | 2024H    | C        | 2026-03-12 03:16:49.628207
(5 rows)
```

## Refleksjonsspørsmål

Besvar refleksjonsspørsmål i filen **besvarelse-refleksjon.md**


## Avslutning

Når du er ferdig:
- Databasen kjører i en Docker-container
- Du kan koble til med `psql`
- Testdata er lastet inn
- Du er klar for oppgave 2

For å stoppe PostgreSQL: `docker-compose down`
For å starte igjen: `docker-compose up -d`
For å slette alle data fra den lokale datamaskinen `docker volume rm <volum_navn>`
