# Besvarelse av refleksjonsspørsmål - DATA1500 Oppgavesett 1.3

Skriv dine svar på refleksjonsspørsmålene fra hver oppgave her.

---

## Oppgave 1: Docker-oppsett og PostgreSQL-tilkobling

### Spørsmål 1: Hva er fordelen med å bruke Docker i stedet for å installere PostgreSQL direkte på maskinen?

**Ditt svar:**

Fordelen med Docker er isolasjon. Ved å kjøre PostgreSQL i en container unngår man konflikter med andre programmer eller 
ulike databaseversjoner på maskinen, da alt ligger i en lukket enhet. Det gjør det enkelt å opprette, endre og slette 
testmiljøer uten at det blir liggende igjen filer i operativsystemet. I tillegg sikrer Docker portabilitet, som betyr at 
databasen vil oppføre seg identisk på alle maskiner (Windows, macOS, Linux) så lenge man bruker samme konfigurasjonsfil.

---

### Spørsmål 2: Hva betyr "persistent volum" i docker-compose.yml? Hvorfor er det viktig?

**Ditt svar:**

Et persistent volum er en lagringsløsning som skiller dataene fra selve containeren. Siden en container er "flyktig" (stateless), 
vil alle data som lagres inni den forsvinne permanent når containeren slettes. Ved å bruke volum kobles databasens filer 
til din fysiske harddisk i stedet. Dette er avgjørende fordi det sikrer at tabeller, brukerdata og konfigurasjoner 
overlever selv om du stopper, sletter eller oppdaterer selve databasetjenesten.

---

### Spørsmål 3: Hva skjer når du kjører `docker-compose down`? Mister du dataene?

**Ditt svar:**

Når man kjører `docker-compose down`, blir alle containerne og det virtuelle nettverket stoppet og fjernet helt fra 
systemet. Man mister ikke dataene, ettersom databasens innhold ligger lagret i det persistente volumet på harddisk. 
Kommandoen fjerner kun selve "maskineriet" som kjører, mens informasjonen i databasen forblir inntakt til neste gang 
prosjektet startes opp (`docker-compose up -d`).

---

### Spørsmål 4: Forklar hva som skjer når du kjører `docker-compose up -d` første gang vs. andre gang.

**Ditt svar:**

Første gang du kjører kommandoen, må Docker laste ned nødvendige "images" fra internett og opprette ressurser som nettverk 
og volum fra bunnen av. Ved andre gangs kjøring er disse ressursene allerede lagret lokalt på maskinen, noe som gjør at 
oppstarten går betydelig raskere. Docker gjenbruker da det eksisterende volumet slik at databasen starter opp med alle 
dataene fra forrige økt inntakt.

---

### Spørsmål 5: Hvordan ville du delt docker-compose.yml-filen med en annen student? Hvilke sikkerhetshensyn må du ta?

**Ditt svar:**

Jeg ville delt docker-compose.yml-filen via en versjonskontrolltjeneste som GitHub eller ved å sende filen direkte, da 
den kun inneholder konfigurasjonen for miljøet og ikke selve databaseinnholdet. Det viktigste sikkerhetshensynet er å 
unngå å skrive sensitive passord og brukernavn direkte i filen. I stedet bør det brukes en separat .env-fil for slike 
opplysninger, slik at konfigurasjonen kan deles trygt uten at private tilgangskoder kommer på avveie.

---

## Oppgave 2: SQL-spørringer og databaseskjema

### Spørsmål 1: Hva er forskjellen mellom INNER JOIN og LEFT JOIN? Når bruker du hver av dem?

**Ditt svar:**

- INNER JOIN: Henter kun rader med match i begge tabeller. Brukes når du bare vil se komplette koblinger 
(f.eks. aktive studenter med fag).
- LEFT JOIN: Henter alt fra venstre tabell, uavhengig av match. Brukes for å beholde en komplett hovedliste og identifisere 
manglende koblinger (f.eks. alle studenter, også de uten fag).
- RIGHT JOIN: Fungerer som en LEFT JOIN, men prioriterer høyre tabell. Brukes sjelden, da man som regel bare bytter 
rekkefølge på tabellene i en LEFT JOIN for bedre lesbarhet.

---

### Spørsmål 2: Hvorfor bruker vi fremmednøkler? Hva skjer hvis du prøver å slette et program som har studenter?

**Ditt svar:**

Fremmednøkler sikrer at data i ulike tabeller henger logisk sammen (referanseintegritet). Hvis vi prøver å slette et program 
som har studenter, vil databasen normalt blokkere slettingen for å hindre at studentene blir stående med en ugyldig referanse.

---

### Spørsmål 3: Forklar hva `GROUP BY` gjør og hvorfor det er nødvendig når du bruker aggregatfunksjoner.

**Ditt svar:**

`GROUP BY` grupperer rader som har samme verdier i spesifikke kolonner. Det er nødvendig ved bruk av aggregatfunksjoner 
for å definere hvilket nivå beregningen skal skje på (f.eks. antall emner per student), slik at vi kan vise både grupperte 
detaljer og beregnede verdier i samme resultat.

---

### Spørsmål 4: Hva er en indeks og hvorfor er den viktig for ytelse?

**Ditt svar:**

En indeks er en sortert datastruktur som fungerer som et oppslagsverk for tabellen. Den er viktig for ytelse fordi den lar 
databasen hoppe direkte til de relevante radene i stedet for å skanne gjennom hele tabellen rad for rad. Dette reduserer 
antall operasjoner drastisk og gjør søk i store datamengder lynraske.

---

### Spørsmål 5: Hvordan ville du optimalisert en spørring som er veldig treg?

**Ditt svar:**

For å optimalisere en treg spørring ville jeg brukt `EXPLAIN ANALYZE` foran spørringen, for å finne nøyaktig hvor 
databasen bruker mest tid. Deretter ville jeg lagt til indekser på relevante kolonner. Primærnøkler får dette automatisk, 
men fremmednøkler, søkekolonner i `WHERE`-ledd og kolonner i `ORDER BY` bør ofte indekseres manuelt. Til slutt ville jeg sørget 
for at spørringen er effektiv ved å bruke spesifikke kolonnenavn i stedet for `SELECT *`, og filtrere tidlig med `WHERE`.

---

## Oppgave 3: Brukeradministrasjon og GRANT

### Spørsmål 1: Hva er prinsippet om minste rettighet? Hvorfor er det viktig?

**Ditt svar:**

Prinsippet om minste rettighet (Principle of Least Privilege) går ut på at brukere kun skal ha de tilgangene som er strengt 
nødvendige for å utføre oppgavene sine. Dette er viktig for å sikre dataintegritet og sikkerhet, da det forhindrer at brukere 
ved en feiltakelse sletter eller endrer kritiske data, samtidig som det begrenser skadeomfanget dersom en brukerkonto blir misbrukt.

---

### Spørsmål 2: Hva er forskjellen mellom en bruker og en rolle i PostgreSQL?

**Ditt svar:**

I PostgreSQL er det i dag ingen teknisk forskjell på en bruker og en rolle. Begge er definert som en ROLE. I praksis brukes 
likevel begrepene ulikt for å skille mellom identitet og tilgang. En "bruker" er en rolle som har LOGIN-rettighet og 
representerer en spesifikk person eller applikasjon, mens en "rolle" uten påloggingsrettighet fungerer som en gruppe for 
å samle spesifikke rettigheter som kan tildeles flere brukere samtidig for enklere administrasjon.

---

### Spørsmål 3: Hvorfor er det bedre å bruke roller enn å gi rettigheter direkte til brukere?

**Ditt svar:**

Å bruke roller forenkler administrasjonen betydelig fordi man kan tildele rettigheter til en logisk gruppe i stedet for 
til hver enkelt person. Når flere brukere skal ha samme tilgang, trenger man bare å legge dem til i den aktuelle rollen 
fremfor å manuelt konfigurere rettigheter for hver konto. Dette reduserer faren for feilkonfigurering og gjør det langt 
mer effektivt å oppdatere eller fjerne tilganger for mange brukere samtidig.

---

### Spørsmål 4: Hva skjer hvis du gir en bruker `DROP` rettighet? Hvilke sikkerhetsproblemer kan det skape?

**Ditt svar:**

Å gi en bruker `DROP`-rettighet skaper en alvorlig sikkerhetsrisiko fordi det tillater permanent sletting av hele 
datastrukturer og tilhørende data uten mulighet for angring i selve databasen. Dette kan føre til totalt datatap og 
nedetid for applikasjoner som er avhengige av disse objektene. Utover faren for menneskelige feil, øker det risikoen ved 
et eventuelt hackerangrep, da en kompromittert konto med slike rettigheter kan utføre sabotasje som er svært tidkrevende 
og kostbar å gjenopprette fra sikkerhetskopier.

---

### Spørsmål 5: Hvordan ville du implementert at en student bare kan se sine egne karakterer, ikke andres?

**Ditt svar:**

Jeg ville opprettet et dynamisk VIEW som filtrerer rader i karaktertabellen basert på kolonnen 
for studentens identifikator (f.eks. e-post eller studentnummer). Ved å bruke funksjonen WHERE student_id = CURRENT_USER, 
sikrer man at databasen automatisk begrenser resultatet til den påloggede brukerens egne rader. Deretter tildeles rollen 
student rettigheten SELECT på selve viewet, mens tilgangen til kildetabellen forblir lukket, slik at studenten aldri kan 
spørre om andres data direkte.

---

## Notater og observasjoner

Bruk denne delen til å dokumentere interessante funn, problemer du møtte, eller andre observasjoner:

[Skriv dine notater her]


## Oppgave 4: Brukeradministrasjon og GRANT

1. **Hva er Row-Level Security og hvorfor er det viktig?**
   - RLS er en sikkerhetsfunksjon som begrenser hvilke rader en bruker kan se eller endre basert på deres identitet eller 
     roller. Det er viktig fordi det flytter sikkerhetslogikken fra applikasjonen til databasen, noe som gir et ekstra lag 
     med beskyttelse mot uautorisert datatilgang.

2. **Hva er forskjellen mellom RLS og kolonnebegrenset tilgang?**
   - RLS filtrerer data horisontalt (bestemmer hvilke rader/individer man ser), mens kolonnebegrenset tilgang filtrerer 
     vertikalt (bestemmer hvilke typer informasjon, som f.eks. "lønn", man har lov til å se for alle rader).

3. **Hvordan ville du implementert at en student bare kan se karakterer for sitt eget program?**
   - Jeg ville opprettet en policy på emneregistreringer som bruker en USING-klausul for å sjekke om program_id i emnet 
     samsvarer med studentens egen program_id via en join eller subquery mot en tabell som kobler studenter til studieprogrammer.

4. **Hva er sikkerhetsproblemene ved å bruke views i stedet for RLS?**
   - Views kan ofte omgås hvis brukeren har direkte tilgang til de underliggende tabellene. RLS er derimot knyttet direkte 
     til tabellen og håndheves uansett hvilken spørring eller verktøy som brukes for å hente ut dataene.

5. **Hvordan ville du testet at RLS-policyer fungerer korrekt?**
   - Ved å bruke SET ROLE [brukernavn] i terminalen for å simulere ulike brukere (student, foreleser, admin) og deretter 
     kjøre SELECT-spørringer for å verifisere at man kun får opp de radene man faktisk skal ha tilgang til.

---

## Referanser

- PostgreSQL dokumentasjon: https://www.postgresql.org/docs/
- Docker dokumentasjon: https://docs.docker.com/

