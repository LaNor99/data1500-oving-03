-- Test 1
SELECT '1. **Hent alle studenter som ikke har noen emneregistreringer**' as test;
SELECT s.fornavn, s.etternavn
FROM studenter s
LEFT JOIN emneregistreringer er ON s.student_id = er.student_id
WHERE er.registrering_id IS NULL;

/* Viser:
 fornavn | etternavn
---------+-----------
(0 rows)
*/


-- Test 2
SELECT '2. **Hent alle emner som ingen studenter er registrert på**' as test;
SELECT e.emne_navn, e.emne_kode
FROM emner e
LEFT JOIN emneregistreringer er ON e.emne_id = er.emne_id
WHERE er.registrering_id IS NULL;

/* Viser:
 emne_navn | emne_kode
-----------+-----------
(0 rows)
*/


-- Test 3
SELECT '3. **Hent studentene med høyeste karakter per emne**' as test;
SELECT s.fornavn, s.etternavn, e.emne_navn, er.karakter
FROM emneregistreringer er
JOIN studenter s ON er.student_id = s.student_id
JOIN emner e ON er.emne_id = e.emne_id
WHERE er.karakter = (SELECT MIN(karakter)
                     FROM emneregistreringer er2
                     WHERE er2.emne_id = er.emne_id);

/* Viser:
 fornavn | etternavn |       emne_navn       | karakter
---------+-----------+-----------------------+----------
 Ola     | Nordmann  | Databaser             | A
 Ola     | Nordmann  | Programmering         | B
 Per     | Larsen    | Databasesystemer      | A
 Anna    | Johansen  | Distribuerte systemer | C
(4 rows)
*/


-- Test 4
SELECT '4. **Lag en rapport som viser hver student, deres program, og antall emner de er registrert på**' as test;
SELECT s.fornavn, s.etternavn, p.program_navn, COUNT(er.emne_id) as antall_emner
FROM studenter s
JOIN programmer p ON s.program_id = p.program_id
LEFT JOIN emneregistreringer er ON s.student_id = er.student_id
GROUP BY s.student_id, s.fornavn, s.etternavn, p.program_navn
ORDER BY antall_emner DESC;

/* Viser:
 fornavn | etternavn |  program_navn  | antall_emner
---------+-----------+----------------+--------------
 Ola     | Nordmann  | Informatikk    |            2
 Kari    | Normann   | Informatikk    |            1
 Per     | Larsen    | Data Science   |            1
 Anna    | Johansen  | Cybersikkerhet |            1
(4 rows)
*/


-- Test 5
SELECT '5. **Hent alle studenter som er registrert på både DATA1500 og DATA1100**' as test;
SELECT s.fornavn, s.etternavn, STRING_AGG(e.emne_kode, ', ') as fagkombinasjon
FROM studenter s
JOIN emneregistreringer er ON s.student_id = er.student_id
JOIN emner e ON er.emne_id = e.emne_id
WHERE e.emne_kode IN ('DATA1500', 'DATA1100')
GROUP BY s.student_id, s.fornavn, s.etternavn
HAVING COUNT(DISTINCT er.emne_id) = 2;

/* Viser:
 fornavn | etternavn |   fagkombinasjon
---------+-----------+--------------------
 Ola     | Nordmann  | DATA1500, DATA1100
(1 row)
*/