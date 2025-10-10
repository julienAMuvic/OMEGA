# Methods Annex draft

**User:** Anonymous (julienmillette@uvic.ca)  
**Created:** 10/1/2025 23:28:46  
**Updated:** 10/3/2025 11:29:43  
**Exported:** 10/10/2025 11:54:00  
**Link:** [https://chatgpt.com/g/g-p-68dd8a031fec8191bbf04d1af55e9971-review/c/68de1b99-e038-832c-b632-faa84f93deb4](https://chatgpt.com/g/g-p-68dd8a031fec8191bbf04d1af55e9971-review/c/68de1b99-e038-832c-b632-faa84f93deb4)  

## Prompt:
Role & style
You are drafting the Methods Annex for the book Many Forms, One Set of Rails. Write in clear, technical prose (policy—rather than academic—voice): numbered subsections, short paragraphs, tables where useful, equations rendered plainly (ASCII), and step-by-step procedures. Avoid purple prose. No external citations—treat this as a self-contained methods chapter. Target length: 1,200–1,800 words.

Purpose
Specify exactly how we measure the five Pillars, aggregate them into the composite Π (geometric mean), quantify uncertainty, run sensitivity analyses, detect gaming (Goodhart), handle missing data, and audit/replicate results. Include a worked numeric example that takes invented but realistic numbers from raw indicators → normalized sub-indices → Pillar scores → Π. Include falsification tests and stop/go thresholds.

1) Indicators to Use (fixed list)

For each Pillar, define the indicator bundle, units, and direction (↑ good, ↓ bad). You will normalize all indicators to [0,1] with monotone transforms and explicitly state them.

Birth / Crew Formation

B1: Completed household formations per 1,000 adults (↑)

B2: 3-year rolling Total Fertility Rate relative to charter target (↑)

B3: First-child age distribution score (penalize extreme delay) (↑)

B4: Dependency coverage ratio (childcare/eldercare slots per dependent) (↑)

Language / Codec

L1: Intergenerational language retention (share of children proficient) (↑)

L2: Work-lexicon fluency (share of adults passing civic/technical glossary test) (↑)

L3: Translation gateway uptime for lingua-franca interfaces (↑)

L4: Public proceedings linguistic accessibility (share with dual-language provision) (↑)

Land / Habitat

H1: Preventive maintenance completion rate (scheduled/required) (↑)

H2: Unplanned outage hours per 1,000 users (↓)

H3: Habitat reserve coverage (days of critical spares/cooling) (↑)

H4: Environmental quality index (composite of air/water/thermal spill) (↑)

Skill / Reliability

S1: Critical guild density (certified maintainers per 10k pop) (↑)

S2: Mean time between failures (MTBF) in critical systems (↑)

S3: Shadow-ops drill pass rate (manual takeovers within SLA) (↑)

S4: Defect escape rate (post-release defects per 1k changes) (↓)

Security (Bounded)

Q1: Adjudicated offense rate per 10k (↓)

Q2: Tribunal interim-order (IO) SLA compliance (≤72h) (↑)

Q3: Green-lane uptime (corridor/SAR/medical) (↑)

Q4: Sanctions-before-shots ratio (sanctions resolved / kinetic incidents) (↑)

2) Data Sources (tell the reader what we assume)

Administrative records: registries, court ledgers, port/corridor logs, SAR reports, maintenance CMMS, guild rosters.

Telemetry aggregates: scheduler uptime, translation gateways, outage meters.

Survey modules (annual/biannual): language proficiency, household formation, lexicon tests.

Audit samples: randomized file reviews, drill observations, teardown lotteries (for lineage/provenance).
Note: All personally identifying data are aggregated before use; methods include a privacy budget and randomization where needed.

3) Normalization & Construction Rules

Normalize each indicator x to a unitless score s ∈ [0,1] using min-max winsorization with posted anchors (A_low, A_high):
s = clamp(0, 1, (x - A_low) / (A_high - A_low)) for ↑ indicators.
For ↓ indicators use s = clamp(0, 1, (A_high - x) / (A_high - A_low)).

Publish anchors per indicator (e.g., MTBF A_low=200h, A_high=1,500h). Update anchors annually with a 3-year rolling window and expert oversight.

Pillar score = geometric mean of its sub-indicator scores (equal weight within pillar by default):
Pillar = (∏ s_i)^(1/k) where k = number of sub-indicators.

Composite Π = geometric mean of the five Pillar scores:
Π = (Birth × Language × Habitat × Skill × Security)^(1/5).

Justification: geometric mean penalizes lopsided performance (no single pillar can compensate for collapse elsewhere).

4) Uncertainty Estimation

Use a block bootstrap at the indicator level (1,000 resamples) to capture sampling and process variance.

For administrative streams with near-census coverage, inject a conservative ±2% observational noise before resampling to avoid zero variance.

Propagate uncertainty through normalization → pillar → Π; report 95% intervals for each pillar and for Π.

Publish SNR (signal-to-noise ratio) per indicator: annual mean divided by bootstrap SD.

5) Sensitivity & Robustness

Run three classes of tests and publish all:

One-at-a-time (OAT) sensitivity: ±10% shocks to each indicator anchor (A_low, A_high) to see ΔΠ and ΔPillar.

Weight perturbation: Re-compute with alternative within-pillar weights (Dirichlet draws) and with pillar-level weights (e.g., favor Security in crisis, Habitat in refurbishment) to show range.

Leave-one-out: Drop each sub-indicator in turn; report Π spread.

Present tornado plots or a sorted table of the top five drivers of Π variance.

6) Goodhart & Gaming Detection

For each indicator, specify gaming signatures and counters:

B1 (household formations): Sudden spike without matching B4 (dependency coverage) → likely paper marriages.
Counter: require joint evidence: co-residence, shared financials, and time-lagged retention.

L2 (lexicon proficiency): Short-term cram effects.
Counter: rotate test pools; include applied tasks; penalize sharp reversion next period.

H1/H2 (maintenance vs outages): Reported H1↑ with flat H2 → maintenance box-ticking.
Counter: cross-check with parts usage and vendor invoices; random site audits.

S3 (shadow-ops drills): Staged drills.
Counter: unannounced drills with external observers.

Q2/Q4 (tribunal & sanctions): Reclassifying incidents to “avoid kinetic” counts.
Counter: third-party log reconciliation; publish definitions and raw counts side-by-side.

Add a CUSUM/SPR sequential test to flag abrupt, uncorroborated improvements in any sub-indicator.

7) Privacy & Data Minimization

Privacy budget per person-year ≤ 200 bits of event data exposed to analytics after aggregation.

Use salted, rotating pseudonyms; publish deletion schedules.

Release only pillar and Π aggregates with 95% intervals; no small-cell tables that risk re-identification.

All audits use on-site secure enclaves; only statistics leave the enclave.

8) Missing Data & Imputation

If any sub-indicator is missing for a locale and period:

If coverage ≥80% across the pillar, impute missing s_i using last observation carried forward, capped at 2 periods, else use regional median.

If coverage <80%, withhold the pillar score and Π for that locale/period and flag “insufficient data.”

Imputed components must be marked; sensitivity re-runs exclude all imputed points, and we report the delta.

9) Worked Numeric Example (show your math)

Create a table like the following; fill with your own consistent numbers and compute step-by-step.

9.1 Raw indicator values (example year, one locale)
Indicator	Value	A_low	A_high	Direction
B1	42 per 1,000	20	60	↑
B2	1.85 vs target 2.10	1.40	2.40	↑
B3	Score 0.68 (0–1 raw)	0.40	0.90	↑
B4	0.78 (slots per dependent, 0–1)	0.50	0.95	↑
L1	0.74	0.40	0.95	↑
L2	0.62	0.30	0.90	↑
L3	0.985 uptime	0.95	0.995	↑
L4	0.81	0.50	1.00	↑
H1	0.88	0.60	0.98	↑
H2	14 hours/1k	60	5	↓
H3	9.0 days	3	15	↑
H4	0.76	0.50	0.95	↑
S1	18 per 10k	6	24	↑
S2	920 hours MTBF	200	1500	↑
S3	0.72	0.40	0.95	↑
S4	0.84 defects/1k	2.0	0.2	↓
Q1	3.6 /10k	18	1	↓
Q2	0.91 SLA hit	0.70	0.98	↑
Q3	0.982 uptime	0.94	0.995	↑
Q4	14:1 ratio	3	20	↑
9.2 Normalize to [0,1]

Show the formula once, then compute each s_i.
Example for B1 (↑): s = (42−20)/(60−20)=0.55.
For H2 (↓): s = (60−14)/(60−5)=0.836.

Populate a second table with all s_i.

9.3 Pillar scores (geometric mean within pillar)

Compute each pillar:

Birth = (B1×B2×B3×B4)^(1/4)

Language = (L1×L2×L3×L4)^(1/4)

Habitat = (H1×H2×H3×H4)^(1/4)

Skill = (S1×S2×S3×S4)^(1/4)

Security = (Q1×Q2×Q3×Q4)^(1/4)

9.4 Composite Π

Π = (Birth × Language × Habitat × Skill × Security)^(1/5)

Report Π and the five pillar scores to three decimals.

9.5 Uncertainty (bootstrap sketch)

Describe one bootstrap resample (e.g., resample indicators with replacement within each pillar), recompute pillar and Π, repeat 1,000×, and report 2.5th/97.5th percentiles.

9.6 Sensitivity snippet

Perturb A_high for MTBF (S2) by +10% and recompute Π; report ΔΠ. Do the same for Q3 A_low (−10%). Present results in a tiny table.

10) Falsifiers & Stop/Go Criteria

Falsifier A (Reliability): If two independent rail implementations cannot maintain a performance spread <5% for 3 consecutive quarters, Π reporting pauses; standards market must be re-opened and retested.

Falsifier B (Justice): If Q3 (green-lane uptime) <0.95 for two consecutive periods, no charter reforms may claim success regardless of Π.

Falsifier C (Goodhart): If ≥3 indicators show CUSUM anomalies uncorroborated by paired metrics (e.g., H1↑ without H2↓), flag the series and rerun audits; suspended from Π until resolved.

Stop/Go: If more than one falsifier fires in the same period, publish Π with a striped watermark (“under audit”) and withhold policy bonuses/rebates tied to Π.

11) Publication & Audit

Release pillar and Π with 95% intervals, SNR table, sensitivity summary, and an exceptions log (missing/imputed data, audits pending).

Post the Methods Annex version and the exact anchors used.

Provide a machine-readable bundle (JSON/CSV) with: raw aggregates, normalized s_i, pillar scores, Π, bootstrap intervals, and sensitivity outputs.

Invite independent reproducibility bounties; pay for first verified re-run that matches within tolerance.

12) Governance of Methods (versioning & change control)

Methods changes require: (1) red-team memo, (2) pilot back-test on 3 prior years, (3) public comment period (30 days), (4) supermajority of the standards committee (with conflict-of-interest disclosures).

Every change increments the Methods Annex minor version; anchor updates increment the patch version; structural changes increment the major version.

13) Plain-Language Summary (2–3 sentences)

Close with a short paragraph any lay reader can grasp: What Π means, why geometric mean, and why we publish uncertainty/sensitivity alongside the score.

Formatting & Output

Use #, ##, ### headings as above.

Include one compact table for the raw→normalized mapping and one for sensitivity deltas.

Keep within 1,200–1,800 words.

Do not include chain-of-thought; summarize calculations and decisions.

Quality checklist for yourself before returning output

 All five pillars covered with the specified indicators.

 Normalization formulas stated for ↑ and ↓.

 Π formula present.

 Bootstrap uncertainty explained; 95% intervals promised.

 Sensitivity (OAT, weights, LOO) covered with at least one tiny example table.

 Goodhart signatures + counters listed for ≥5 indicators.

 Worked numeric example complete through Π.

 Falsifiers and stop/go rules stated.

 Privacy/minimization stated with a budget.

 Publication/audit & versioning defined.

## Response:
Thought for 25s

Methods Annex — Measuring the Five Pillars and Composite Π
==========================================================

1\. Scope and Purpose
---------------------

1.1 This annex specifies how to: (a) compute scores for the Five Pillars; (b) aggregate them into the composite Π via geometric means; (c) quantify uncertainty; (d) run sensitivity and robustness checks; (e) detect gaming (Goodhart); (f) handle missing data; and (g) audit and reproduce results.

1.2 Design principles: transparency, monotone transforms, conservative anchors, and publication of uncertainty and sensitivity alongside point estimates.

* * *

2\. Indicators (fixed list)
---------------------------

For each Pillar, the indicator bundle, units, and direction are fixed. All will be normalized to \[0,1\].

### 2.1 Birth / Crew Formation

*   **B1** Completed household formations per 1,000 adults (↑)
*   **B2** 3-year rolling Total Fertility Rate relative to charter target (↑)
*   **B3** First-child age distribution score (penalize extreme delay) (↑)
*   **B4** Dependency coverage ratio (childcare/eldercare slots per dependent) (↑)

### 2.2 Language / Codec

*   **L1** Intergenerational language retention (share of children proficient) (↑)
*   **L2** Work-lexicon fluency (share of adults passing civic/technical glossary test) (↑)
*   **L3** Translation gateway uptime for lingua-franca interfaces (↑)
*   **L4** Public proceedings linguistic accessibility (share with dual-language provision) (↑)

### 2.3 Land / Habitat

*   **H1** Preventive maintenance completion rate (scheduled/required) (↑)
*   **H2** Unplanned outage hours per 1,000 users (↓)
*   **H3** Habitat reserve coverage (days of critical spares/cooling) (↑)
*   **H4** Environmental quality index (composite of air/water/thermal spill) (↑)

### 2.4 Skill / Reliability

*   **S1** Critical guild density (certified maintainers per 10k pop) (↑)
*   **S2** Mean time between failures (MTBF) in critical systems (↑)
*   **S3** Shadow-ops drill pass rate (manual takeovers within SLA) (↑)
*   **S4** Defect escape rate (post-release defects per 1k changes) (↓)

### 2.5 Security (Bounded)

*   **Q1** Adjudicated offense rate per 10k (↓)
*   **Q2** Tribunal interim-order SLA compliance (≤72h) (↑)
*   **Q3** Green-lane uptime (corridor/SAR/medical) (↑)
*   **Q4** Sanctions-before-shots ratio (sanctions resolved / kinetic incidents) (↑)

* * *

3\. Data Sources (assumptions)
------------------------------

3.1 **Administrative records:** registries, court ledgers, port/corridor logs, SAR reports, CMMS maintenance systems, and guild rosters.

3.2 **Telemetry aggregates:** scheduler uptime, translation gateways, outage meters.

3.3 **Survey modules (annual/biannual):** language proficiency, household formation, lexicon tests.

3.4 **Audit samples:** randomized file reviews, drill observations, teardown lotteries (for lineage/provenance).

3.5 **Privacy:** personally identifying data are aggregated before use; a privacy budget and controlled randomization apply where needed (see §10).

* * *

4\. Normalization and Construction
----------------------------------

4.1 Each indicator  $x$  is mapped to a unitless score  $s \in [0,1]$  via min–max with winsorized anchors  $(A_{\text{low}}, A_{\text{high}})$ .

*   **For ↑ indicators**:  
    `s = clamp(0,1, (x - A_low) / (A_high - A_low))`
*   **For ↓ indicators**:  
    `s = clamp(0,1, (A_high - x) / (A_high - A_low))`

4.2 Anchors are posted per indicator (e.g., S2 MTBF:  $A_{\text{low}}=200$  h,  $A_{\text{high}}=1500$  h), updated annually using a 3-year rolling window and expert oversight.

4.3 **Pillar scores** use geometric means with equal within-pillar weights by default:  
`Pillar = (∏ s_i)^(1/k)` where  $k$  is the number of sub-indicators.

4.4 **Composite Π** is the geometric mean across the five Pillars:  
`Π = (Birth × Language × Habitat × Skill × Security)^(1/5)`.

4.5 **Rationale:** the geometric mean penalizes lopsided performance; no single pillar can mask collapse elsewhere.

* * *

5\. Uncertainty Estimation
--------------------------

5.1 **Block bootstrap (indicator level):** For each locale-year, draw 1,000 resamples by sampling indicator rows with replacement **within pillars** (preserving within-pillar dependence). For administrative streams with near-census coverage, add ±2% mean-zero observational noise before resampling.

5.2 For each resample, recompute normalized  $s_i$ , Pillars, and Π. Report **95% intervals** (2.5th/97.5th percentiles) for each Pillar and for Π.

5.3 Publish **signal-to-noise ratio (SNR)** per indicator: annual mean divided by bootstrap SD.

* * *

6\. Sensitivity and Robustness
------------------------------

6.1 **One-at-a-time (OAT) anchor sensitivity:** For each indicator, shock  $A_{\text{low}}$  and  $A_{\text{high}}$  by ±10% and recompute Pillars and Π; publish ΔΠ and the top five drivers.

6.2 **Weight perturbations:**

*   **Within-pillar:** random Dirichlet draws over sub-indicator weights.
*   **Across pillars:** scenario weights (e.g., Security-weighted during crises). Publish the resulting bands.

6.3 **Leave-one-out:** Drop each sub-indicator in turn; report Π spread.

6.4 Present tornado plots **or** a sorted table of drivers of Π variance.

* * *

7\. Goodhart and Gaming Detection
---------------------------------

7.1 We define gaming signatures and counters per indicator; examples (≥5 shown):

*   **B1 Household formations:** sudden spike without matching **B4** coverage → paper marriages.  
    _Counter:_ require joint evidence (co-residence + shared financials) and check 12-month retention.
*   **L2 Lexicon proficiency:** short-term cramming.  
    _Counter:_ rotate test pools; include applied tasks; penalize sharp reversion next period.
*   **H1/H2 Maintenance vs outages:** reported **H1**↑ with flat **H2** → box-ticking.  
    _Counter:_ cross-check with parts usage and vendor invoices; random site audits.
*   **S3 Shadow-ops drills:** staged drills.  
    _Counter:_ unannounced drills with external observers and cross-team tasking.
*   **Q2/Q4 Tribunal & sanctions:** reclassifying incidents to improve Q4.  
    _Counter:_ third-party log reconciliation; publish definitions and raw counts side-by-side.

7.2 **CUSUM/SPR sequential tests**: for each sub-indicator, run change-point detection; flag abrupt improvements lacking corroboration in paired metrics; route to audit.

* * *

8\. Privacy and Data Minimization
---------------------------------

8.1 Privacy budget ≤ **200 bits** of event data per person-year exposed to analytics after aggregation.

8.2 Salted, rotating pseudonyms for linkage; published deletion schedules.

8.3 Release only Pillar and Π aggregates with 95% intervals; no small-cell tables.

8.4 Audits run within on-site secure enclaves; only statistics exit.

* * *

9\. Missing Data and Imputation
-------------------------------

9.1 If any sub-indicator is missing:

*   If pillar coverage ≥80%: impute missing  $s_i$  by last observation carried forward (max 2 periods) or the regional median if no history.
*   If pillar coverage <80%: withhold the pillar and Π for that locale/period; flag **insufficient data**.

9.2 Mark all imputed components; rerun sensitivity excluding imputed points; publish deltas.

* * *

10\. Worked Numeric Example (one locale, one year)
--------------------------------------------------

### 10.1 Raw → normalized (anchors and direction shown)

Normalization formula (once):

*   ↑: `s = (x − A_low) / (A_high − A_low)`
*   ↓: `s = (A_high − x) / (A_high − A_low)`  
    Clamp to \[0,1\].

| Ind. | Value | A\_low | A\_high | Dir | s\_i |
| --- | --- | --- | --- | --- | --- |
| B1 | 42 per 1,000 | 20 | 60 | ↑ | 0.550 |
| B2 | 1.85 vs 2.10 | 1.40 | 2.40 | ↑ | 0.450 |
| B3 | 0.68 | 0.40 | 0.90 | ↑ | 0.560 |
| B4 | 0.78 | 0.50 | 0.95 | ↑ | 0.622 |
| L1 | 0.74 | 0.40 | 0.95 | ↑ | 0.618 |
| L2 | 0.62 | 0.30 | 0.90 | ↑ | 0.533 |
| L3 | 0.985 | 0.950 | 0.995 | ↑ | 0.778 |
| L4 | 0.81 | 0.50 | 1.00 | ↑ | 0.620 |
| H1 | 0.88 | 0.60 | 0.98 | ↑ | 0.737 |
| H2 | 14 h/1k | 60 | 5 | ↓ | 0.164 |
| H3 | 9.0 days | 3 | 15 | ↑ | 0.500 |
| H4 | 0.76 | 0.50 | 0.95 | ↑ | 0.578 |
| S1 | 18 /10k | 6 | 24 | ↑ | 0.667 |
| S2 | 920 h MTBF | 200 | 1500 | ↑ | 0.554 |
| S3 | 0.72 | 0.40 | 0.95 | ↑ | 0.582 |
| S4 | 0.84 /1k | 2.0 | 0.2 | ↓ | 0.356 |
| Q1 | 3.6 /10k | 18 | 1 | ↓ | 0.153 |
| Q2 | 0.91 | 0.70 | 0.98 | ↑ | 0.750 |
| Q3 | 0.982 | 0.94 | 0.995 | ↑ | 0.764 |
| Q4 | 14:1 | 3 | 20 | ↑ | 0.647 |

### 10.2 Pillar scores (geometric means)

*   **Birth** = (0.550 × 0.450 × 0.560 × 0.622)^(1/4) = **0.542**
*   **Language** = (0.618 × 0.533 × 0.778 × 0.620)^(1/4) = **0.631**
*   **Habitat** = (0.737 × 0.164 × 0.500 × 0.578)^(1/4) = **0.432**
*   **Skill** = (0.667 × 0.554 × 0.582 × 0.356)^(1/4) = **0.526**
*   **Security** = (0.153 × 0.750 × 0.764 × 0.647)^(1/4) = **0.488**

### 10.3 Composite Π

`Π = (Birth × Language × Habitat × Skill × Security)^(1/5)`  
`Π = (0.542 × 0.631 × 0.432 × 0.526 × 0.488)^(1/5) = 0.520` (to three decimals).

### 10.4 Uncertainty (bootstrap sketch)

*   Build 1,000 resamples at the **indicator** level with replacement; add ±2% noise to near-census streams.
*   For each: re-normalize, recompute pillars and Π.
*   Report 2.5th/97.5th percentiles for each pillar and Π (e.g., Π 95% CI = \[0.497, 0.542\] if obtained).
*   Publish SNR per indicator.

### 10.5 Sensitivity snippet (OAT, anchors)

Perturb anchors and recompute Π; report ΔΠ (absolute change from 0.520).

| Test | Anchor change | Π (new) | ΔΠ |
| --- | --- | --- | --- |
| S2 MTBF (Skill) | A\_high +10% (1500→1650) | 0.517 | −0.003 |
| Q3 Green-lane (Security) | A\_low −10% (0.94→0.846) | 0.524 | +0.005 |

Interpretation: Π is modestly sensitive to Security corridor uptime anchors and less so to MTBF upper anchors in this scenario.

* * *

11\. Falsifiers and Stop/Go Criteria
------------------------------------

11.1 **Falsifier A — Reliability:** If two independent rail implementations cannot maintain a performance spread <5% for three consecutive quarters, Π reporting pauses; re-open the standards market and retest.

11.2 **Falsifier B — Justice:** If **Q3** (green-lane uptime) <0.95 for two consecutive periods, no charter reforms may claim success irrespective of Π.

11.3 **Falsifier C — Goodhart:** If ≥3 indicators show CUSUM anomalies uncorroborated by paired metrics (e.g., **H1**↑ without **H2**↓), flag the series; suspend from Π until audits resolve.

11.4 **Stop/Go:** If >1 falsifier fires in the same period, publish Π with a striped watermark (“under audit”) and withhold any policy bonuses/rebates tied to Π.

* * *

12\. Publication and Audit
--------------------------

12.1 Release: (a) Pillar and Π point estimates; (b) 95% intervals; (c) SNR table; (d) sensitivity summary (top five drivers); (e) exceptions log (missing/imputed components, audits pending).

12.2 Post the Methods Annex version number and **the exact anchors used** that period.

12.3 Provide a machine-readable bundle (JSON/CSV) containing: raw aggregates, normalized  $s_i$ , pillar scores, Π, bootstrap intervals, and sensitivity outputs.

12.4 **Reproducibility bounties:** invite independent reruns; pay the first verified replication within tolerance.

* * *

13\. Governance of Methods (versioning and change control)
----------------------------------------------------------

13.1 Changes require: (1) red-team memo; (2) pilot back-test on three prior years; (3) 30-day public comment; (4) supermajority of the standards committee with conflict-of-interest disclosures.

13.2 **Versioning:**

*   Structural method changes: **major** version.
*   Anchor updates: **patch** version.
*   Other method tweaks: **minor** version.

13.3 All historical releases archive the code, anchors, and outputs to enable exact reproduction.

* * *

14\. Implementation Notes (operational)
---------------------------------------

14.1 **Posting anchors:** For each indicator, publish  $A_{\text{low}}$  and  $A_{\text{high}}$ , last three years’ values, and rationale (e.g., historical percentiles or policy targets).

14.2 **Winsorization:** Values beyond anchors are clamped at 0 or 1; never extrapolate above 1.

14.3 **Locale comparability:** Use the same anchors across comparable locales; if material heterogeneity exists, define families of locales with family-specific anchors and disclose.

14.4 **Crisis overrides:** Temporary pillar weights may be published for crisis windows (e.g., Security-weighted), but **Π (equal-weighted) remains the canonical headline**; crisis-weighted Π\* may be shown as a secondary series with clear labeling.

* * *

15\. Quality Controls (checklist)
---------------------------------

*    Anchors posted and documented.
*    Raw → normalized mapping reproducible from released bundle.
*    Bootstrap CI computed (1,000 draws) and SNR published.
*    OAT, weight, and leave-one-out sensitivity completed; top drivers listed.
*    CUSUM/SPR run; anomalies triaged; audits logged.
*    Missing data rules applied and flagged; imputation deltas published.
*    Falsifiers evaluated; stop/go actions documented if triggered.
*    Version numbers incremented and archived.

* * *

16\. Plain-Language Summary (2–3 sentences)
-------------------------------------------

Π is a single reliability score built from five Pillars—Birth, Language, Habitat, Skill, and Security—each measured by a small set of indicators. We use geometric means so weakness in one area cannot be hidden by strength in another. Every release includes uncertainty bands and sensitivity tests so readers can see how stable the score is and how it would move under reasonable assumptions.

