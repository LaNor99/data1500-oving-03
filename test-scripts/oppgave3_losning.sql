-- Test 1
SELECT '1. **Opprett en rolle `program_ansvarlig` som kan lese og oppdatere programmer-tabellen, men ikke slette**' as test;
-- Sletter rollen hvis den finnes, slik at skriptet kan kjøres på nytt uten feil
DROP ROLE IF EXISTS program_ansvarlig;
CREATE ROLE program_ansvarlig LOGIN PASSWORD 'program_pass';
GRANT SELECT, UPDATE ON programmer TO program_ansvarlig;


-- Test 2
SELECT '2. **Opprett en rolle `student_self_view` som bare kan se sitt eget studentdata (hint: bruk en VIEW)**' as test;
-- Først lager vi et VIEW
CREATE OR REPLACE VIEW student_self_view AS
SELECT * FROM studenter
WHERE epost = CURRENT_USER;

-- Deretter oppretter vi rollen (vi sletter den først så skriptet kan kjøres på nytt), og gir tilgang til VIEW-et
DROP ROLE IF EXISTS student_self_role;
CREATE ROLE student_self_role LOGIN PASSWORD 'self_pass';
GRANT SELECT ON student_self_view TO student_self_role;


-- Test 3
SELECT '3. **Gi `foreleser_role` tilgang til å lese fra `student_view` (som allerede er opprettet)**' as test;
GRANT SELECT ON student_view TO foreleser_role;


-- Test 4
SELECT '4. **Opprett en rolle `backup_bruker` som bare har SELECT-rettighet på alle tabeller**' as test;
DROP ROLE IF EXISTS backup_bruker;
CREATE ROLE backup_bruker LOGIN PASSWORD 'backup_pass';
-- Gir bare SELECT-rettigheter på alle tabeller
GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup_bruker;


-- Test 5
SELECT '5. **Lag en oversikt over alle roller og deres rettigheter**' as test;
-- Viser en kompakt oversikt over rettigheter per tabell for relevante roller,
-- filtrert for å fjerne systemstøy og uaktuelle tabeller.
SELECT grantee AS rolle, table_name AS tabell, string_agg(privilege_type, ', ') AS rettigheter
FROM information_schema.role_table_grants
WHERE grantee NOT LIKE 'pg_%'
  AND grantee NOT IN ('postgres', 'PUBLIC', 'admin')
  AND table_name IN ('studenter', 'emner', 'programmer', 'emneregistreringer', 'student_view', 'student_self_view')
GROUP BY grantee, table_name
ORDER BY rolle, tabell;

/* Viser:
        rolle        |       tabell       |                          rettigheter
---------------------+--------------------+---------------------------------------------------------------
 admin_role          | emner              | INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
 admin_role          | emneregistreringer | INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
 admin_role          | programmer         | SELECT, UPDATE, DELETE, INSERT, TRUNCATE, REFERENCES, TRIGGER
 admin_role          | studenter          | DELETE, INSERT, SELECT, UPDATE, TRUNCATE, REFERENCES, TRIGGER
 backup_bruker       | emner              | SELECT
 backup_bruker       | emneregistreringer | SELECT
 backup_bruker       | programmer         | SELECT
 backup_bruker       | student_self_view  | SELECT
 backup_bruker       | student_view       | SELECT
 backup_bruker       | studenter          | SELECT
 emne_leser          | emner              | SELECT
 foreleser_role      | emner              | INSERT, SELECT, UPDATE
 foreleser_role      | emneregistreringer | SELECT, INSERT
 foreleser_role      | programmer         | INSERT, UPDATE, SELECT
 foreleser_role      | student_view       | SELECT
 foreleser_role      | studenter          | UPDATE, SELECT, INSERT
 karakter_oppdaterer | emner              | SELECT
 karakter_oppdaterer | emneregistreringer | UPDATE, SELECT
 karakter_oppdaterer | studenter          | SELECT
 program_ansvarlig   | programmer         | SELECT, UPDATE
 student_role        | emner              | SELECT
 student_role        | emneregistreringer | SELECT
 student_role        | programmer         | SELECT
 student_role        | student_view       | SELECT
 student_role        | studenter          | SELECT
 student_self_role   | student_self_view  | SELECT
(26 rows)
 */