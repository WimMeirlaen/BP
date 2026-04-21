# Bachelorproef: Kernthema's uit Script-Analyse

## Samenvatting in 30 Seconden

Je twee scripts vormen een **geautomatiseerde twee-fase migratiepijplijn** van OneNote → RDM:
1. **Export-script:** Zet OneNote-notitieboeken om naar HTML, organiseert per klant
2. **Import-script:** Injecteert HTML-inhoud in RDM-vaults met slimme matching en duplicate-detectie

De scripts zijn robuust genoeg voor **onbewakte nacht-runs** (hence "Queue management"). Ze implementeren geavanceerde technieken om challenges op te lossen die inherent zijn aan data-migratie.

---

## Top 10 Thesis-Worthy Discussie-Punten

Kies er 3-5 voor diepere analyse in je bachelorproef:

### **1. Fuzzy Matching als Kern-Challenge**
**Vraag:** Hoe voorkomen we mismatch tussen klant-namen in OneNote (bv. "Klant ABC") en RDM (bv. "Customer ABC")?

**Waarop baseren de scripts:**
- `Score-Match()` functie met name-normalisatie, token-overlap berekening
- Toont top-5-matches aan gebruiker; geen blind automation

**Thesis-waarde:**
- Literatuurgebruik: string matching algorithms (Levenshtein, Jaro-Winkler, soundex)
- Praktijk: hoe maak je 95%+ accuracy zonder false positives?
- Uitbreiding: machine learning approaches?

---

### **2. Unattended Batch Processing & Resilience**
**Vraag:** Hoe laat je PowerShell-scripts 's nachts draaien zonder crashes door user-clicks?

**Waarop baseren de scripts:**
- Disabelen van Windows Quick Edit Mode (P/Invoke naar kernel32.dll)
- Queue-based architecture: alle user-input vooraf, dan batch geen verdere vragen
- Exponential backoff bij API throttling (HTTP 429)

**Thesis-waarde:**
- Systems design: hoe abstractiseer je user-interactie uit kritieke stappen?
- Reliabiliteit: retry policies, logging, state tracking
- Best practices: automation patterns in enterprise omgevingen

---

### **3. PAM & Credentials-in-Transit Beveiliging**
**Vraag:** Hoe bescherm je gevoelige credentials (wachtwoorden!) die van OneNote naar RDM migreren?

**Waarop baseren de scripts:**
- Credentials in RDM zijn encryptie, audit trail, vault
- Credentials in OneNote zijn platte tekst, geen logging
- Migratie-periode: tussentijdse HTML-bestanden kunnen gevoelig zijn

**Thesis-waarde:**
- PAM-principes toepassen op migratieprocedures
- End-to-end veiligheid: van source tot destination
- Compliance: GDPR/ISO27001 vereisten voor gevoelige data in-transit
- Verband naar je bestaande inleiding (OneNote lacks sensitivity labels)

---

### **4. Data Integrity & Duplicate Detection**
**Vraag:** Hoe garandeer je dat alles correct gemigreerd wordt en we geen duplicaten krijgen?

**Waarop baseren de scripts:**
- `RunDuplicateSweepEachItem` flag: detecteert items die al in RDM bestaan
- Audit logs: X items exported, Y items imported, Z mismatches
- Reconciliation reports als validation-mechanisme

**Thesis-waarde:**
- Data quality assurance in batch-processen
- Definities van "duplicate" (exact match vs semantic similarity)
- Risk-mitigation: wat als import faalt halverwege?

---

### **5. API Rate Limiting & Intelligent Backoff**
**Vraag:** Microsoft Graph limiteert requests (429 Too Many Requests); hoe ga je daarmee om?

**Waarop baseren de scripts:**
- Intelligente herpauze van 30 minuten (met progress-bar) i.p.v. blind retry
- Throttle-handling is ingebouwd in export-loop
- Logging van throttle-events voor later analyse

**Thesis-waarde:**
- Cloud API constraints begrijpen (rate limits, quotas)
- Algoritmische benadering: exponential backoff vs linear backoff vs adaptive
- Overhead analysis: hoeveel extra tijd kost throttling in practice?

---

### **6. Configuration-Driven Architecture**
**Vraag:** Hoe flexibiliseer je scripts zodat ze voor veel verschillende scenarios werken?

**Waarop baseren de scripts:**
- `migration-config.json` centraliseert migratie-beleid
- Environment variables voor credentials (geen hardcoding)
- Flags voor optionele behavior (SkipCleanup, AutoConfirmQueue, etc.)

**Thesis-waarde:**
- Infrastructure-as-Code principles
- Environment specialization (dev/staging/prod)
- Secrets management best practices
- Operationeel: hoe makkeijk is het voor junior-admins om config aan te passen?

---

### **7. Two-Phase Architecture (Export + Import)**
**Vraag:** Waarom twee aparte scripts i.p.v. één intégré migratie?

**Waarop baseren de scripts:**
- **Export:** Ontkoppeld van RDM, kan offline debugging
- **Import:** Heeft artefacten (HTML-folders) als input, niet live OneNote
- **Voordeel:** je kan exportbestanden inspekten/valideren tussentijds

**Thesis-waarde:**
- Separation of concerns & modularity
- Debugging & validation opportunities
- Fail-safe: broken exports "stoppen" niet de hele pipeline

---

### **8. HTML Content Reconstruction Complexities**
**Vraag:** OneNote → HTML export is niet triviaal; hoe hanteren we broken/ugly HTML?

**Waarop baseren de scripts:**
- Analyse deel (Analyze-Hydrex-Full.ps1) parst complex HTML
- Attachments inlined als base64
- Links kunnen broken zijn
- Tabellen kunnen malformed zijn

**Thesis-waarde:**
- Content transformation challenges
- Lossless vs lossy migraties: wat mag zoekraken?
- Quality validation: hoe meet je content-integriteit?

---

### **9. Least-Privilege & Role-Based Access Control**
**Vraag:** Hoe zorg je dat migratie-scripts alleen doen wat nodig is, niet meer?

**Waarop baseren de scripts:**
- Scripts filteren op "read-only" datasources → kunnen daar niet schrijven
- Credentials ingesteld per datasource: niet allem RDM—, maar specifieke vault
- Audit logging: wie heeft welke scripts met welke parameters gedraaid?

**Thesis-waarde:**
- RBAC-principes in automation context
- Threat model: wat kan fout gaan als scripts te veel hebben?
- Segregation of duties: scripts-beheerder ≠ vault-beheerder

---

### **10. Phased Rollout & Change Management**
**Vraag:** Je kunt niet 100+ klanten in 1 nacht migreren; hoe pilot je?

**Waarop baseren de scripts:**
- CompletedCustomersFile tracking: weet welke klanten al gedaan zijn
- Queue-architectuur: kan per run een subset selecteren
- Logging per klant: kan fouten snel debuggen

**Thesis-waarde:**
- Project management: pilot → staged rollout → full production
- Risk management: minimale blast radius
- Feedback loops: leren van early pilots voor latere runs

---

## Suggestie: Selectie & Diepte

### **Optie A: Breed (5-6 topics)**
- Behandel elk topic in 1-2 pagina's
- Brede dekking van technische, operationele, beveiligings-aspecten
- Beste voor generalist-bachelorproef

### **Optie B: Diep (2-3 topics)**
- Ga echt in de diepte: literatur, experiments, evaluations
- Bv. "Fuzzy Matching" + "Data Integrity" + "Change Management"
- Beste als je wilt publiceren/conferences

### **Optie C: Hybride (Aanbevolen)**
- 1-2 diepte-topics
- 2-3 overview-topics
- Balans tussen specialisatie en breedheid

---

## Correlatie naar Bestaande Bachelorproef-Structuur

Kijk naar je inleiding & standvanzaken:

- **PAM-focus:** Verwijs naar topic #3 (credentials beveiliging)
- **Governance & Compliance:** Topics #3, #6, #9
- **Technical challenges:** Topics #1, #4, #5, #8
- **Operational aspects:** Topics #2, #7, #10

---

## Quick Reference: Per Topic → Mogelijke Subtitels

```
1. Fuzzy Matching
   → "Entity Resolution in Heterogeneous Data Sources"
   → "Name Disambiguation in Automated Migration Pipelines"

2. Batch Resilience
   → "Designing Unattended Batch Processes: Lessons from Overnight Migrations"
   → "Robust Automation for Enterprise Data Movement"

3. PAM in Transit
   → "Securing Privileged Information During Migration: A PAM Perspective"
   → "Zero-Trust Principles in Data Pipeline Design"

4. Data Integrity
   → "Quality Assurance in Automated Bulk Migrations"
   → "Duplicate Detection and Reconciliation at Scale"

5. Rate Limiting
   → "Handling Cloud API Constraints in Batch Workflows"
   → "Adaptive Backoff Strategies for SaaS Integration"

6. Configuration-Driven
   → "Infrastructure as Code for Enterprise Automation"
   → "Flexible Migration Pipelines Through Policy Separation"

7. Two-Phase Design
   → "Modular Architecture in Data Migration Pipelines"
   → "Staged Processing for Reliability and Debuggability"

8. HTML Content
   → "Lossy vs Lossless Content Transformation"
   → "Format Normalization in Heterogeneous Document Migration"

9. RBAC & Least Privilege
   → "Applying Zero-Trust to Automation Scripts"
   → "Minimizing Script Blast Radius Through RBAC"

10. Phased Rollout
    → "Pilot-to-Production Pathways for Enterprise Automation"
    → "Risk-Managed Adoption of Automated System Migrations"
```

---

## Aanbevolen Schrijfstructuur

```
Hoofdstuk X: Implicaties van Script-Analyse

6.1 Architecturale Keuzes
    6.1.1 Two-Phase Design (topic #7)
    6.1.2 Queue Management (topic #2)
    6.1.3 Configuration-Driven Approach (topic #6)

6.2 Technische Challenges
    6.2.1 Fuzzy Matching (topic #1)
    6.2.2 HTML Content Transformation (topic #8)
    6.2.3 API Rate Limiting (topic #5)

6.3 Data Integrity & Governance
    6.3.1 Duplicate Detection (topic #4)
    6.3.2 Least-Privilege Automation (topic #9)
    6.3.3 PAM in Migration Context (topic #3)

6.4 Operational Lessons
    6.4.1 Phased Rollout Strategy (topic #10)
    6.4.2 Monitoring & Observability
    6.4.3 Knowledge Transfer & Documentation

Conclusie & Toekomstwerk
    → Recommendations voor schaling
    → Integratie van AI/ML in matching
    → Compliance-verificatie
```

---

## Debugging-tips Tijdens Schrijven

1. **Voor elk topic:** Toon 1-2 code-fragmenten die de challenge illustreren
2. **Verband naar literature:** Elke technische claim moet een academische bron hebben
3. **Praktische implicaties:** "Waarom zou een lezer dit interessant vinden?"
4. **Metrics:** Waar mogelijk: getallen/benchmarks (X% match-accuracy, Y minuten throttle, etc.)

---

**Succes met je bachelorproef! 🎓**
