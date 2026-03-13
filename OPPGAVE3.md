# Oppgave 3: Brukeradministrasjon og GRANT

## Læringsmål

Etter å ha fullført denne oppgaven skal du:
- Forstå rollen som databaseadministrator (DBA)
- Opprette brukere og roller i PostgreSQL
- Tildele rettigheter med GRANT
- Forstå prinsippet om minste rettighet (Principle of Least Privilege)
- Teste tilgang fra ulike brukerkontoer

## Bakgrunn

**Databaseadministrator (DBA)** er ansvarlig for:
- Brukeradministrasjon (opprette/slette brukere)
- Sikkerhetskopier og gjenoppretting
- Overvåking og optimalisering
- Tilgangsadministrasjon (GRANT/REVOKE)

**Prinsippet om minste rettighet:** En bruker skal bare ha de rettighetene som er nødvendig for å utføre sitt arbeid. For eksempel:
- **Admin:** Full tilgang
- **Foreleser:** Lese- og skrive-tilgang til studentdata
- **Student:** Kun lese-tilgang til sitt eget data

**GRANT-syntaks:**
```sql
GRANT <rettigheter> ON <objekt> TO <bruker/rolle>;
```

**Rettigheter:**
- `SELECT` - Lese data
- `INSERT` - Legge til data
- `UPDATE` - Endre data
- `DELETE` - Slette data
- `ALL` - Alle rettigheter

## Oppgave

### Del 1: Verifiser eksisterende roller

Databasen har allerede tre roller opprettet. Verifiser dem (kan også vurdere å bruke pgAdmin eller DBeaver:

```bash
	$ docker-compoes exec postgres psql -U admin -d data1500_db
```

Passord: `admin123`

Kjør:
```sql
-- Vis alle roller
SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';

-- Vis rettigheter for admin_role
SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE grantee = 'admin_role';
```
Vis alle roller:
rolname
----------------
admin
admin_role
foreleser_role
student_role
(4 rows)

Vis rettigheter for admin_role:
  grantee  | privilege_type
-----------+----------------
admin_role | INSERT
admin_role | SELECT
admin_role | UPDATE
admin_role | DELETE
admin_role | TRUNCATE
admin_role | REFERENCES
admin_role | TRIGGER
admin_role | INSERT
admin_role | SELECT
admin_role | UPDATE
admin_role | DELETE
admin_role | TRUNCATE
admin_role | REFERENCES
admin_role | TRIGGER
admin_role | INSERT
admin_role | SELECT
admin_role | UPDATE
admin_role | DELETE
admin_role | TRUNCATE
admin_role | REFERENCES
admin_role | TRIGGER
admin_role | INSERT
admin_role | SELECT
admin_role | UPDATE
admin_role | DELETE
admin_role | TRUNCATE
admin_role | REFERENCES
admin_role | TRIGGER
(28 rows)

### Del 2: Test tilgang som foreleser

Åpne en ny terminal og koble til som foreleser:

```bash
	$ docker-compose exec postgres psql -U foreleser_role -d data1500_db
```

Passord: `foreleser_pass`

Prøv disse kommandoene:

```sql
-- Skal fungere (SELECT)
SELECT * FROM studenter;

-- Skal fungere (INSERT)
INSERT INTO studenter (fornavn, etternavn, epost, program_id) 
VALUES ('Test', 'Bruker', 'test@example.com', 1);

-- Skal IKKE fungere (DELETE)
DELETE FROM studenter WHERE student_id = 1;
```

Hva skjer? Dokumenter resultatene.

`SELECT` viser:
student_id | fornavn | etternavn |              epost               | program_id |         opprettet
-----------+---------+-----------+----------------------------------+------------+---------------------------
1 | Ola     | Nordmann  | ola.nordmann@student.oslomet.no  |          1 | 2026-03-12 03:16:49.62627
2 | Kari    | Normann   | kari.normann@student.oslomet.no  |          1 | 2026-03-12 03:16:49.62627
3 | Per     | Larsen    | per.larsen@student.oslomet.no    |          2 | 2026-03-12 03:16:49.62627
4 | Anna    | Johansen  | anna.johansen@student.oslomet.no |          3 | 2026-03-12 03:16:49.62627
(4 rows)

`INSERT` viser: INSERT 0 1
Studenter-tabellen er oppdatert til:
student_id | fornavn | etternavn |              epost               | program_id |         opprettet
-----------+---------+-----------+----------------------------------+------------+----------------------------
1 | Ola     | Nordmann  | ola.nordmann@student.oslomet.no  |          1 | 2026-03-12 03:16:49.62627
2 | Kari    | Normann   | kari.normann@student.oslomet.no  |          1 | 2026-03-12 03:16:49.62627
3 | Per     | Larsen    | per.larsen@student.oslomet.no    |          2 | 2026-03-12 03:16:49.62627
4 | Anna    | Johansen  | anna.johansen@student.oslomet.no |          3 | 2026-03-12 03:16:49.62627
5 | Test    | Bruker    | test@example.com                 |          1 | 2026-03-13 07:39:04.349166
(5 rows)

`DELETE` viser:
ERROR:  permission denied for table studenter

Resultatene bekrefte at foreleser_role følger prinsippet om minste rettighet. Rollen har fått tildelt `SELECT` og `INSERT` 
for å kunne administrere studentlisten, men mangler `DELETE`. Dette er et sikkerhetstiltak for å forhindre utilsiktet 
sletting av viktige data, selv for roller med skrive-tilgang.

### Del 3: Test tilgang som student

Åpne en ny terminal og koble til som student:

```bash
	docker-compose exec postgres psql -U student_role -d data1500_db
```

Passord: `student_pass`

Prøv disse kommandoene:

```sql
-- Skal fungere (SELECT)
SELECT * FROM studenter;

-- Skal IKKE fungere (INSERT)
INSERT INTO studenter (fornavn, etternavn, epost, program_id) 
VALUES ('Test', 'Bruker', 'test@example.com', 1);

-- Skal IKKE fungere (UPDATE)
UPDATE studenter SET fornavn = 'Ola' WHERE student_id = 1;
```

Hva skjer? Dokumenter resultatene.

`SELECT` viser:
student_id | fornavn | etternavn |              epost               | program_id |         opprettet
-----------+---------+-----------+----------------------------------+------------+----------------------------
         1 | Ola     | Nordmann  | ola.nordmann@student.oslomet.no  |          1 | 2026-03-12 03:16:49.62627
         2 | Kari    | Normann   | kari.normann@student.oslomet.no  |          1 | 2026-03-12 03:16:49.62627
         3 | Per     | Larsen    | per.larsen@student.oslomet.no    |          2 | 2026-03-12 03:16:49.62627
         4 | Anna    | Johansen  | anna.johansen@student.oslomet.no |          3 | 2026-03-12 03:16:49.62627
         5 | Test    | Bruker    | test@example.com                 |          1 | 2026-03-13 07:39:04.349166
(5 rows)

`INSERT` viser:
ERROR:  permission denied for table studenter

`UPDATE` viser:
ERROR:  permission denied for table studenter

Testen bekrefter at student_role kun har lese-tilgang (`SELECT`). Forsøk på å legge til nye rader (`INSERT`) eller endre 
eksisterende data (`UPDATE`) blir blokkert av databasen med feilmeldingen 'permission denied'. Dette samsvarer med prinsippet 
om at en student kun skal kunne se informasjon, ikke administrere den.

### Del 4: Opprett ny rolle med begrenset tilgang

Som admin, opprett en ny rolle som bare kan lese emner:

```bash
	# Koble til som admin
	$ docker-compose exec postgres psql -U admin -d data1500_db
```

```sql
-- Opprett rollen
CREATE ROLE emne_leser LOGIN PASSWORD 'emne_pass';

-- Se i metadata om rollen er laget 
SELECT * FROM pg_roles WHERE rolname = 'emne_leser';

-- Gi kun SELECT-rettighet på emner-tabellen
GRANT SELECT ON emner TO emne_leser;

-- Verifiser
SELECT * FROM information_schema.role_table_grants 
WHERE grantee = 'emne_leser';
```

Verifisering viser:
 grantor |  grantee   | table_catalog | table_schema | table_name | privilege_type | is_grantable | with_hierarchy
---------+------------+---------------+--------------+------------+----------------+--------------+----------------
 admin   | emne_leser | data1500_db   | public       | emner      | SELECT         | NO           | YES
(1 row)

Test tilgangen:

```bash
	$ docker-compose exec postgres psql -U emne_leser -d data1500_db
```

Passord: `emne_pass`

```sql
-- Skal fungere
SELECT * FROM emner;

-- Skal IKKE fungere
SELECT * FROM studenter;
```

`SELECT * FROM emner` viser:
 emne_id | emne_kode |       emne_navn       | studiepoeng |            beskrivelse            |         opprettet      
---------+-----------+-----------------------+-------------+-----------------------------------+----------------------------
       1 | DATA1500  | Databaser             |          10 | Introduksjon til databaser og SQL | 2026-03-12 03:16:49.624784
       2 | DATA1100  | Programmering         |          10 | Introduksjon til programmering    | 2026-03-12 03:16:49.624784
       3 | DATA2200  | Databasesystemer      |          10 | Avanserte databasekonsepter       | 2026-03-12 03:16:49.624784
       4 | DATA3100  | Distribuerte systemer |          10 | Distribuerte databasesystemer     | 2026-03-12 03:16:49.624784
(4 rows)

`SELECT * FROM studenter` viser:
ERROR:  permission denied for table studenter

### Del 5: Opprett rolle med UPDATE-rettighet

Opprett en rolle som kan oppdatere karakterer:

```sql
-- Koble til som admin
psql -h localhost -U admin -d data1500_db

-- Opprett rollen
CREATE ROLE karakter_oppdaterer LOGIN PASSWORD 'karakter_pass';

-- Gi SELECT og UPDATE på emneregistreringer
GRANT SELECT, UPDATE ON emneregistreringer TO karakter_oppdaterer;

-- Gi SELECT på relaterte tabeller (for JOIN)
GRANT SELECT ON studenter, emner TO karakter_oppdaterer;
```

Verifisering viser:
 grantor |  grantee   | table_catalog | table_schema | table_name | privilege_type | is_grantable | with_hierarchy
---------+------------+---------------+--------------+------------+----------------+--------------+----------------
 admin   | emne_leser | data1500_db   | public       | emner      | SELECT         | NO           | YES
(1 row)

Test tilgangen:

```bash
	$ docker-compose exec postgres psql -U karakter_oppdaterer -d data1500_db
```

Passord: `karakter_pass`

```sql
-- Skal fungere (SELECT)
SELECT * FROM emneregistreringer;

-- Skal fungere (UPDATE)
UPDATE emneregistreringer SET karakter = 'A' 
WHERE registrering_id = 1;

-- Skal IKKE fungere (DELETE)
DELETE FROM emneregistreringer WHERE registrering_id = 1;
```

`SELECT` viser:
 registrering_id | student_id | emne_id | semester | karakter |      registrert_dato
-----------------+------------+---------+----------+----------+----------------------------
               1 |          1 |       1 | 2024H    | A        | 2026-03-12 03:16:49.628207
               2 |          1 |       2 | 2024H    | B        | 2026-03-12 03:16:49.628207
               3 |          2 |       1 | 2024H    | B        | 2026-03-12 03:16:49.628207
               4 |          3 |       3 | 2024H    | A        | 2026-03-12 03:16:49.628207
               5 |          4 |       4 | 2024H    | C        | 2026-03-12 03:16:49.628207
(5 rows)

`UPDATE` viser: UPDATE 1

`DELETE` viser:
ERROR:  permission denied for table emneregistreringer

### Del 6: Revoke-rettigheter

Fjern UPDATE-rettighet fra foreleser_role:

```sql
-- Koble til som admin
psql -h localhost -U admin -d data1500_db

-- Fjern UPDATE-rettighet
REVOKE UPDATE ON emneregistreringer FROM foreleser_role;

-- Verifiser
SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE grantee = 'foreleser_role';
```

Verifisering viser:
    grantee     | privilege_type
----------------+----------------
 foreleser_role | INSERT
 foreleser_role | SELECT
 foreleser_role | INSERT
 foreleser_role | SELECT
 foreleser_role | UPDATE
 foreleser_role | INSERT
 foreleser_role | SELECT
 foreleser_role | UPDATE
 foreleser_role | INSERT
 foreleser_role | SELECT
 foreleser_role | UPDATE
 foreleser_role | INSERT
 foreleser_role | SELECT
 foreleser_role | UPDATE
(14 rows)

Test at foreleser ikke lenger kan oppdatere:

```bash
	$ docker-compose exec postgres psql -h localhost -U foreleser_role -d data1500_db
```

```sql
-- Skal IKKE fungere lenger
UPDATE emneregistreringer SET karakter = 'B' 
WHERE registrering_id = 1;
```

`UPDATE` viser:
ERROR:  permission denied for table emneregistreringer

## Oppgaver du skal løse

1. **Opprett en rolle `program_ansvarlig` som kan lese og oppdatere programmer-tabellen, men ikke slette**

2. **Opprett en rolle `student_self_view` som bare kan se sitt eget studentdata (hint: bruk en VIEW)**

3. **Gi `foreleser_role` tilgang til å lese fra `student_view` (som allerede er opprettet)**

4. **Opprett en rolle `backup_bruker` som bare har SELECT-rettighet på alle tabeller**

5. **Lag en oversikt over alle roller og deres rettigheter**

**Viktig:** Lagre alle SQL-spørringene og SQL-setnigene dine i en fil `oppgave3_losning.sql` i mappen `test-scripts` for 
at man kan teste disse med kommando (OBS! du må forsikre at spørringene / setnignen ikke påvirker databaseintegritet/ønsket 
resultat, hvis de utføres flere ganger):

```bash
docker-compose exec postgres psql -U admin -d data1500_db -f test-scripts/oppgave3_losning.sql
```

## Refleksjonsspørsmål

Besvar refleksjonsspørsmål i filen **besvarelse-refleksjon.md**


## Avslutning

Når du er ferdig:
- Du forstår brukeradministrasjon i PostgreSQL
- Du kan tildele og fjerne rettigheter med GRANT/REVOKE
