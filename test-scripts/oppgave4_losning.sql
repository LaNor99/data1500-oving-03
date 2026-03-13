-- 1. **Implementer RLS på `studenter`-tabellen slik at studenter bare ser sitt eget data**
      -- Hint: Bruk samme pattern som `emneregistreringer`
SELECT '1. Implementer RLS på `studenter`-tabellen' as test;

-- Aktiver RLS på studenter-tabellen
ALTER TABLE studenter ENABLE ROW LEVEL SECURITY;

-- Opprett POLICY som gjør at studenter bare ser sin egen data i studenter-tabellen
CREATE POLICY student_see_own_data ON studenter
    FOR SELECT
    USING (
        student_id = (
            SELECT student_id FROM bruker_student_mapping
            WHERE brukernavn = current_user
        )
    );

-- Verifisering:
SELECT * FROM pg_policies WHERE tablename = 'studenter';
/* Viser:
 schemaname | tablename |      policyname      | permissive |  roles   |  cmd   |                             qual                             | with_check
------------+-----------+----------------------+------------+----------+--------+--------------------------------------------------------------+------------
 public     | studenter | student_see_own_data | PERMISSIVE | {public} | SELECT | (student_id = ( SELECT bruker_student_mapping.student_id     |
            |           |                      |            |          |        |    FROM bruker_student_mapping                               |
            |           |                      |            |          |        |   WHERE (bruker_student_mapping.brukernavn = CURRENT_USER))) |
(1 row)
 */


-- 2. **Opprett en policy som tillater foreleser å se alle karakterer**
      -- Hint: Opprett en policy for `foreleser_role` uten USING-betingelse
SELECT '2. Opprett en policy som tillater foreleser å se alle karakterer' as test;

CREATE POLICY foreleser_see_all_grades ON emneregistreringer
    FOR SELECT
    TO foreleser_role
    USING (true);

-- Verifisering:
SELECT * FROM pg_policies WHERE tablename = 'emneregistreringer';
/* Viser:
 schemaname |     tablename      |        policyname        | permissive |      roles       |  cmd   |                             qual                             | with_check
------------+--------------------+--------------------------+------------+------------------+--------+--------------------------------------------------------------+------------
 public     | emneregistreringer | student_see_own_grades   | PERMISSIVE | {public}         | SELECT | (student_id = ( SELECT bruker_student_mapping.student_id     |
            |                    |                          |            |                  |        |    FROM bruker_student_mapping                               |
            |                    |                          |            |                  |        |   WHERE (bruker_student_mapping.brukernavn = CURRENT_USER))) |
 public     | emneregistreringer | foreleser_update_grades  | PERMISSIVE | {public}         | UPDATE | true                                                         | true
 public     | emneregistreringer | foreleser_select_all     | PERMISSIVE | {foreleser_role} | SELECT | true                                                         |
 public     | emneregistreringer | foreleser_see_all_grades | PERMISSIVE | {foreleser_role} | SELECT | true                                                         |
(4 rows)
 */


-- 3. **Lag en view `foreleser_karakteroversikt` som viser studentnavn, emnenavn og karakterer**
      -- Hint: JOIN `studenter`, `emner` og `emneregistreringer`
SELECT '3. Lag en view `foreleser_karakteroversikt` som viser studentnavn, emnenavn og karakterer' as test;

CREATE VIEW foreleser_karakteroversikt AS
SELECT fornavn, etternavn, emne_navn, karakter
FROM studenter s
JOIN emneregistreringer er ON s.student_id = er.student_id
JOIN emner e ON er.emne_id = e.emne_id;

-- Gi tilgang på VIEW-et til forelesere
GRANT SELECT ON foreleser_karakteroversikt TO foreleser_role;

-- Verifisering:
SELECT * FROM foreleser_karakteroversikt;
/* Viser:
 fornavn | etternavn |       emne_navn       | karakter
---------+-----------+-----------------------+----------
 Ola     | Nordmann  | Databaser             | A
 Kari    | Normann   | Databaser             | B
 Ola     | Nordmann  | Programmering         | B
 Per     | Larsen    | Databasesystemer      | A
 Anna    | Johansen  | Distribuerte systemer | C
(5 rows)
 */


-- 4. **Implementer en policy som forhindrer at noen sletter karakterer (bare admin kan gjøre det)**
      -- Hint: Bruk `FOR DELETE` i policyen
SELECT '4. Implementer en policy som forhindrer at noen sletter karakterer' as test;

CREATE POLICY deny_delete_grades ON emneregistreringer
    FOR DELETE
    TO PUBLIC
    USING (false);

-- Verifisering:
SELECT policyname, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'emneregistreringer' AND cmd = 'DELETE';
/* Viser:
     policyname     |  roles   |  cmd   | qual
--------------------+----------+--------+-------
 deny_delete_grades | {public} | DELETE | false
(1 row)
 */


-- 5. **Lag en audit-tabell som logger alle endringer av karakterer**
      -- Hint: Bruk triggers (se Bonus-seksjonen under)
SELECT '5. Lag en audit-tabell som logger alle endringer av karakterer' as test;

-- Opprett audit-tabell
CREATE TABLE audit_log_grade_changes (
    log_id SERIAL PRIMARY KEY,
    tabell_navn VARCHAR(50),
    operasjon VARCHAR(10),
    bruker VARCHAR(50),
    endret_data JSONB,
    endret_tid TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Opprett trigger-funksjon
CREATE OR REPLACE FUNCTION log_grade_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_log_grade_changes (tabell_navn, operasjon, bruker, endret_data)
        VALUES (TG_TABLE_NAME, TG_OP, current_user,
                jsonb_build_object('student_id', OLD.student_id, 'slettet_karakter', OLD.karakter));
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_log_grade_changes (tabell_navn, operasjon, bruker, endret_data)
        VALUES (TG_TABLE_NAME, TG_OP, current_user,
                jsonb_build_object('student_id', NEW.student_id, 'fra', OLD.karakter, 'til', NEW.karakter));
    ELSE
        INSERT INTO audit_log_grade_changes (tabell_navn, operasjon, bruker, endret_data)
        VALUES (TG_TABLE_NAME, TG_OP, current_user, to_jsonb(NEW));
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Aktiver triggeren på emneregistreringer (der karakterene ligger)
CREATE TRIGGER grade_changes_audit
    AFTER INSERT OR UPDATE OR DELETE ON emneregistreringer
    FOR EACH ROW EXECUTE FUNCTION log_grade_changes();

-- Verifisering:
-- Oppdater en karakter som foreleser
UPDATE emneregistreringer SET karakter = 'B' WHERE registrering_id = 1;

-- Se audit-loggen
SELECT * FROM audit_log_grade_changes;
/* Viser:
 log_id |    tabell_navn     | operasjon | bruker |                endret_data                |         endret_tid
--------+--------------------+-----------+--------+-------------------------------------------+----------------------------
      1 | emneregistreringer | UPDATE    | admin  | {"fra": "A", "til": "B", "student_id": 1} | 2026-03-13 12:43:24.633727
(1 row)
 */