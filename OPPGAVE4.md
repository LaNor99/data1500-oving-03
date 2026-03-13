# Oppgave 4: Sikkerhet og Row-Level Security (RLS)

## Læringsmål

Etter å ha fullført denne oppgaven skal du:
- Forstå Row-Level Security (RLS) og når det brukes
- Implementere RLS-policyer i PostgreSQL
- Forstå brukeradministrasjon og rollehierarkier
- Implementere sikre views for dataisolasjon
- Forstå sikkerhetshensyn ved databasedesign

## Bakgrunn

**Row-Level Security (RLS)** er en mekanisme som begrenser hvilke rader en bruker kan se basert på en policy. For eksempel:
- En student skal bare se sine egne karakterer
- En foreleser skal bare se karakterer for sine emner
- En admin skal se alt

**Bruker vs Rolle:**
- **Bruker:** En individuell konto som kan logge inn (f.eks. `student_1`, `foreleser_1`)
- **Rolle:** En gruppe av brukere med felles rettigheter (f.eks. `student_role`, `foreleser_role`)

**Kolonnebegrenset tilgang** betyr at noen brukere ikke kan se visse kolonner. For eksempel:
- Studenter skal ikke se e-postadresser til andre studenter
- Bare admin skal se passord-hashes

**Views** er virtuelle tabeller som kan brukes til å implementere sikkerhet:
```sql
CREATE VIEW student_karakterer AS
SELECT student_id, emne_navn, karakter
FROM emneregistreringer
WHERE student_id = (
    SELECT student_id FROM bruker_student_mapping 
    WHERE brukernavn = current_user
);
```

## Oppgave

### Del 1: Opprett Individuelle Student-Brukere og Roller

**Hva du skal gjøre:**
- Opprett `student_role` rollen
- Opprett individuelle student-brukere (`student_1`, `student_2`, `student_3`)
- Gjør studentene medlemmer av `student_role`
- Opprett `bruker_student_mapping`-tabell for å koble brukernavn til student-ID

**Koble til som admin:**

Husk `docker-compose exec postgres` foran `psql`-kommandoen, hvis kommandoen utføres fra vertsmaskinen.

```bash
docker-compose exec postgres psql -U admin -d data1500_db
# Password: admin123
```

**Kjør SQL-kommandoene:**

```sql
-- ============================================================
-- 1. Opprett student_role
-- ============================================================
CREATE ROLE student_role;

-- ============================================================
-- 2. Opprett individuelle student-brukere
-- ============================================================
CREATE USER student_1 WITH PASSWORD 'student123';
CREATE USER student_2 WITH PASSWORD 'student123';
CREATE USER student_3 WITH PASSWORD 'student123';

-- ============================================================
-- 3. Gjør studentene medlemmer av student_role
-- ============================================================
GRANT student_role TO student_1;
GRANT student_role TO student_2;
GRANT student_role TO student_3;

-- ============================================================
-- 4. Opprett bruker-student mapping-tabell
-- ============================================================
CREATE TABLE bruker_student_mapping (
    brukernavn TEXT PRIMARY KEY,
    student_id INT REFERENCES studenter(student_id)
);

-- Legg til mappinger
INSERT INTO bruker_student_mapping VALUES ('student_1', 1);
INSERT INTO bruker_student_mapping VALUES ('student_2', 2);
INSERT INTO bruker_student_mapping VALUES ('student_3', 3);

-- ============================================================
-- 5. Gi SELECT-rettigheter på tabeller
-- ============================================================
GRANT SELECT ON emneregistreringer TO student_role;
GRANT SELECT ON bruker_student_mapping TO student_role;
GRANT SELECT ON studenter TO student_role;
GRANT SELECT ON emner TO student_role;
GRANT SELECT ON programmer TO student_role;

-- ============================================================
-- 6. Gi USAGE på skjema
-- ============================================================
GRANT USAGE ON SCHEMA public TO student_role;

-- ============================================================
-- 7. Verifiser rettigheter
-- ============================================================
\du
\dp emneregistreringer
```

`\du` viser:
                                                 List of roles
            Role name            |                         Attributes                         |   Member of
---------------------------------+------------------------------------------------------------+----------------
 admin                           | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
 admin_role                      |                                                            | {}
 backup_bruker                   |                                                            | {}
 emne_leser                      |                                                            | {}
 foreleser_role                  |                                                            | {}
 karakter_oppdaterer             |                                                            | {}
 ola.nordmann@student.oslomet.no |                                                            | {}
 program_ansvarlig               |                                                            | {}
 student_1                       |                                                            | {student_role}
 student_2                       |                                                            | {student_role}
 student_3                       |                                                            | {student_role}
 student_role                    |                                                            | {}
 student_self_role               |                                                            | {}

`\du emneregistreringer` viser:
           List of roles
 Role name | Attributes | Member of
-----------+------------+-----------


### Del 2: Implementer RLS for Studenter

**Hva du skal gjøre:**
- Aktivér RLS på `emneregistreringer`-tabellen
- Opprett RLS-policy som sikrer at hver student kun ser sine egne karakterer
- Test at policyen fungerer

**Kjør SQL-kommandoene:**

```sql
-- ============================================================
-- 1. Aktivér RLS på emneregistreringer
-- ============================================================
ALTER TABLE emneregistreringer ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 2. Opprett RLS-policy for studenter
-- ============================================================
-- Studenter ser bare sine egne karakterer
CREATE POLICY student_see_own_grades ON emneregistreringer
    FOR SELECT
    USING (
        student_id = (
            SELECT student_id FROM bruker_student_mapping 
            WHERE brukernavn = current_user
        )
    );

-- ============================================================
-- 3. Verifiser policyen
-- ============================================================
SELECT * FROM pg_policies WHERE tablename = 'emneregistreringer';
```

Verifiseringen viser:
 schemaname |     tablename      |       policyname       | permissive |  roles   |  cmd   |                             qual                             | with_check
------------+--------------------+------------------------+------------+----------+--------+--------------------------------------------------------------+------------
 public     | emneregistreringer | student_see_own_grades | PERMISSIVE | {public} | SELECT | (student_id = ( SELECT bruker_student_mapping.student_id     |
            |                    |                        |            |          |        |    FROM bruker_student_mapping                               |
            |                    |                        |            |          |        |   WHERE (bruker_student_mapping.brukernavn = CURRENT_USER))) |
(1 row)


### Del 3: Test RLS for Studenter

**Test 1: Logg inn som student_1**

```bash
docker-compose exec postgres psql -U student_1 -d data1500_db
# Password: student123
```

```sql
-- Skal bare se karakterer for student_1 (student_id = 1)
SELECT * FROM emneregistreringer;
-- Forventet: 1 rad (student_1 sine karakterer)

-- Prøv å se karakterer for student_2 (skal IKKE fungere)
SELECT * FROM emneregistreringer WHERE student_id = 2;
-- Forventet: 0 rader (RLS-policyen blokkerer det)

-- Avslutt
\q
```

`SELECT * FROM emneregistreringer;` viser:
 registrering_id | student_id | emne_id | semester | karakter |      registrert_dato
-----------------+------------+---------+----------+----------+----------------------------
               2 |          1 |       2 | 2024H    | B        | 2026-03-12 03:16:49.628207
               1 |          1 |       1 | 2024H    | A        | 2026-03-12 03:16:49.628207
(2 rows)

`SELECT * FROM emneregistreringer WHERE student_id = 2;` viser:
 registrering_id | student_id | emne_id | semester | karakter | registrert_dato
-----------------+------------+---------+----------+----------+-----------------
(0 rows)

**Test 2: Logg inn som student_2**

```bash
docker-compose exec postgres psql -U student_2 -d data1500_db
# Password: student123
```

```sql
-- Skal bare se karakterer for student_2 (student_id = 2)
SELECT * FROM emneregistreringer;
-- Forventet: 1 rad (student_2 sine karakterer)

-- Viser:
 registrering_id | student_id | emne_id | semester | karakter |      registrert_dato
-----------------+------------+---------+----------+----------+----------------------------
               3 |          2 |       1 | 2024H    | B        | 2026-03-12 03:16:49.628207
(1 row)

-- Avslutt
\q
```
Viser:
 registrering_id | student_id | emne_id | semester | karakter |      registrert_dato
-----------------+------------+---------+----------+----------+----------------------------
               3 |          2 |       1 | 2024H    | B        | 2026-03-12 03:16:49.628207
(1 row)

**Test 3: Logg inn som student_3**

```bash
docker-compose exec postgres psql -U student_3 -d data1500_db
# Password: student123
```

```sql
-- Skal bare se karakterer for student_3 (student_id = 3)
SELECT * FROM emneregistreringer;
-- Forventet: 1 rad (student_3 sine karakterer)
   
-- Viser:
 registrering_id | student_id | emne_id | semester | karakter |      registrert_dato
-----------------+------------+---------+----------+----------+----------------------------
               4 |          3 |       3 | 2024H    | A        | 2026-03-12 03:16:49.628207
(1 row)

-- Avslutt
\q
```

**Test 4: Logg inn som admin (skal se alle)**

```bash
docker-compose exec postgres psql -U admin -d data1500_db
# Password: admin123
```

```sql
-- Admin skal se alle karakterer (RLS gjelder ikke for admin)
SELECT * FROM emneregistreringer;
-- Forventet: 4 rader (alle karakterer)
   
-- Viser:
 registrering_id | student_id | emne_id | semester | karakter |      registrert_dato
-----------------+------------+---------+----------+----------+----------------------------
               2 |          1 |       2 | 2024H    | B        | 2026-03-12 03:16:49.628207
               3 |          2 |       1 | 2024H    | B        | 2026-03-12 03:16:49.628207
               4 |          3 |       3 | 2024H    | A        | 2026-03-12 03:16:49.628207
               5 |          4 |       4 | 2024H    | C        | 2026-03-12 03:16:49.628207
               1 |          1 |       1 | 2024H    | A        | 2026-03-12 03:16:49.628207
(5 rows)

-- Avslutt
\q
```

### Del 4: Kolonnebegrenset Tilgang Med Views

**Hva du skal gjøre:**
- Opprett en view som skjuler e-postadresser fra studenter
- Gi studenter tilgang til viewet, men ikke original-tabellen

**Koble til som admin:**

```bash
docker-compose exec postgres psql -U admin -d data1500_db
# Password: admin123
```

**Kjør SQL-kommandoene:**

```sql
-- ============================================================
-- 1. Opprett view uten e-postadresser
-- ============================================================
CREATE VIEW student_info_limited AS
SELECT 
    student_id,
    fornavn,
    etternavn,
    program_id
FROM studenter;

-- ============================================================
-- 2. Gi studenter tilgang til viewet
-- ============================================================
GRANT SELECT ON student_info_limited TO student_role;

-- ============================================================
-- 3. Fjern tilgang til original-tabellen
-- ============================================================
REVOKE SELECT ON studenter FROM student_role;
```

**Test som student:**

```bash
docker-compose exec postgres psql -U student_1 -d data1500_db
# Password: student123
```

```sql
-- Skal fungere (viewet)
SELECT * FROM student_info_limited;
-- Forventet: Alle studenter (uten e-postadresser)
   
-- Viser:
 student_id | fornavn | etternavn | program_id
------------+---------+-----------+------------
          1 | Ola     | Nordmann  |          1
          2 | Kari    | Normann   |          1
          3 | Per     | Larsen    |          2
          4 | Anna    | Johansen  |          3
          5 | Test    | Bruker    |          1
(5 rows)

-- Skal IKKE fungere (original-tabellen)
SELECT * FROM studenter;
-- Forventet: Feil "permission denied for table studenter"
   
-- Viser: 
ERROR:  permission denied for table studenter

-- Skal IKKE kunne se e-postadresser
SELECT epost FROM student_info_limited;
-- Forventet: Feil "column epost does not exist"
   
-- Viser:
ERROR:  column "epost" does not exist

-- Avslutt
\q
```

### Del 5: Sikker Karakteroppdatering (Bonus)

**Hva du skal gjøre:**
- Opprett `foreleser_role` med UPDATE-rettigheter
- Opprett policy som tillater foreleser å oppdatere karakterer
- Test at foreleser kan oppdatere karakterer

**Koble til som admin:**

```bash
pdocker-compose exec postgres sql -U admin -d data1500_db
# Password: admin123
```

**Kjør SQL-kommandoene:**

```sql
-- ============================================================
-- 1. Opprett foreleser_role
-- ============================================================
CREATE ROLE foreleser_role;

-- ============================================================
-- 2. Opprett foreleser-bruker
-- ============================================================
CREATE USER foreleser_1 WITH PASSWORD 'foreleser123';

-- ============================================================
-- 3. Gjør foreleser medlem av foreleser_role
-- ============================================================
GRANT foreleser_role TO foreleser_1;

-- ============================================================
-- 4. Gi foreleser SELECT og UPDATE-rettigheter
-- ============================================================
GRANT SELECT ON emneregistreringer TO foreleser_role;
GRANT UPDATE ON emneregistreringer TO foreleser_role;

-- ============================================================
-- 5. Opprett policy for foreleser UPDATE
-- ============================================================
CREATE POLICY foreleser_update_grades ON emneregistreringer
    FOR UPDATE
    USING (true)
    WITH CHECK (true);
```

**Test som foreleser:**

```bash
docker-compose exec postgres psql -U foreleser_1 -d data1500_db
# Password: foreleser123
```

For at sql-spørringene nedenfor skal funke for foreleser_1, må vi gi brukeren lesetilgang til mapping-tabellen. Og 
opprette en SELECT-policy spesifikt for forelesere.
```sql
-- Gi foreleser-rollen lese-tilgang til mapping-tabellen
GRANT SELECT ON bruker_student_mapping TO foreleser_role;

-- Opprett en SELECT-policy spesifikt for forelesere
CREATE POLICY foreleser_select_all ON emneregistreringer
    FOR SELECT 
    TO foreleser_role 
    USING (true);
```

```sql
-- Skal se alle karakterer
SELECT * FROM emneregistreringer;

-- Viser:
 registrering_id | student_id | emne_id | semester | karakter |      registrert_dato
-----------------+------------+---------+----------+----------+----------------------------
               2 |          1 |       2 | 2024H    | B        | 2026-03-12 03:16:49.628207
               3 |          2 |       1 | 2024H    | B        | 2026-03-12 03:16:49.628207
               4 |          3 |       3 | 2024H    | A        | 2026-03-12 03:16:49.628207
               5 |          4 |       4 | 2024H    | C        | 2026-03-12 03:16:49.628207
               1 |          1 |       1 | 2024H    | A        | 2026-03-12 03:16:49.628207
(5 rows)

-- Skal kunne oppdatere karakterer
UPDATE emneregistreringer SET karakter = 'A' WHERE registrering_id = 1;

-- Viser: UPDATE 1

-- Verifiser oppdateringen
SELECT * FROM emneregistreringer WHERE registrering_id = 1;

-- Viser:
 registrering_id | student_id | emne_id | semester | karakter |      registrert_dato
-----------------+------------+---------+----------+----------+----------------------------
               1 |          1 |       1 | 2024H    | A        | 2026-03-12 03:16:49.628207
(1 row)

-- Avslutt
\q
```

## Oppgaver du skal løse

1. **Implementer RLS på `studenter`-tabellen slik at studenter bare ser sitt eget data**
   - Hint: Bruk samme pattern som `emneregistreringer`

2. **Opprett en policy som tillater foreleser å se alle karakterer**
   - Hint: Opprett en policy for `foreleser_role` uten USING-betingelse

3. **Lag en view `foreleser_karakteroversikt` som viser studentnavn, emnenavn og karakterer**
   - Hint: JOIN `studenter`, `emner` og `emneregistreringer`

4. **Implementer en policy som forhindrer at noen sletter karakterer (bare admin kan gjøre det)**
   - Hint: Bruk `FOR DELETE` i policyen

5. **Lag en audit-tabell som logger alle endringer av karakterer**
   - Hint: Bruk triggers (se Bonus-seksjonen under)

**Viktig:** Lagre alle SQL-spørringene og SQL-setnigene dine i en fil `oppgave4_losning.sql` i mappen `test-scripts` for 
at man kan teste disse med kommando (OBS! du må forsikre at spørringene / setnignen ikke påvirker databaseintegritet/ønsket 
resultat, hvis de utføres flere ganger):

```bash
docker-compose exec postgres psql -U admin -d data1500_db -f test-scripts/oppgave3_losning.sql
```

## Refleksjonsspørsmål

Besvar refleksjonsspørsmål i filen **besvarelse-refleksjon.md**


## Avslutning

Når du er ferdig:
- Du forstår Row-Level Security og brukeradministrasjon
- Du kan begynne å implementere sikre views og RLS-policyer
- Du forstår sikkerhetshensyn ved databasedesign
- Du har en mulighet til å begynne med databaseadministrasjon i praksis!


## Bonus: Audit-Logging Med Triggers

Implementer en audit-tabell som logger alle endringer:

```sql
-- ============================================================
-- 1. Opprett audit_log-tabell
-- ============================================================
CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    tabell_navn VARCHAR(50),
    operasjon VARCHAR(10),
    bruker VARCHAR(50),
    endret_data JSONB,
    endret_tid TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 2. Opprett trigger-funksjon
-- ============================================================
CREATE OR REPLACE FUNCTION log_changes()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (tabell_navn, operasjon, bruker, endret_data)
    VALUES (TG_TABLE_NAME, TG_OP, current_user, to_jsonb(NEW));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 3. Aktiver triggeren på emneregistreringer
-- ============================================================
CREATE TRIGGER emneregistreringer_audit
AFTER INSERT OR UPDATE OR DELETE ON emneregistreringer
FOR EACH ROW EXECUTE FUNCTION log_changes();

-- ============================================================
-- 4. Test audit-logging
-- ============================================================
-- Oppdater en karakter som foreleser
UPDATE emneregistreringer SET karakter = 'A+' WHERE registrering_id = 1;

-- Se audit-loggen
SELECT * FROM audit_log;

-- Viser:
 log_id |    tabell_navn     | operasjon | bruker |                                                                  endret_data                                                                  |         endret_tid
--------+--------------------+-----------+--------+-----------------------------------------------------------------------------------------------------------------------------------------------+----------------------------
      1 | emneregistreringer | UPDATE    | admin  | {"emne_id": 1, "karakter": "A+", "semester": "2024H", "student_id": 1, "registrering_id": 1, "registrert_dato": "2026-03-12T03:16:49.628207"} | 2026-03-13 12:55:14.168072
(1 row)
```

---

**Lykke til med oppgaven! 🎓**
