# Phase 5 — AML Monitoring Framework
## Gaming Compliance & Risk Intelligence Platform

---

## 1. Overview

This framework defines **11 rule-based AML monitoring typologies** for a regulated
online gaming operator, aligned to FINTRAC expectations for ongoing transaction
monitoring — covering transaction-behaviour typologies plus **sanctions/watchlist
screening**. Each rule produces scored alerts that flow into `Fact_AML_Alerts` and,
where warranted, escalate into STR cases (Phase 6).

Rules are intentionally **transparent and rule-based** (not black-box ML) so that
every alert is explainable to an investigator and a regulator — a core requirement
in regulated compliance environments.

---

## 2. Risk Scoring Methodology

Every rule carries a **base risk score (0–100)**. The alert's severity is derived
from its score:

| Risk Score | Severity | Handling |
|---|---|---|
| 0–39 | Low | Logged, batch review |
| 40–69 | Medium | Analyst review queue |
| 70–89 | High | Priority review, auto-escalate |
| 90–100 | Critical | Immediate escalation |

**Escalation rule:** any alert with score **≥ 70** is auto-flagged
`Is_Escalated = 1`. When a single transaction triggers multiple rules, each match is
a separate alert row (grain = transaction × rule); the **account's aggregate risk**
is the max score across its open alerts, used for prioritization.

---

## 3. The 10 AML Rules

> Threshold note: CAD 10,000 is the FINTRAC large-transaction reporting reference
> point. "Structuring" thresholds sit deliberately just below it.

### AML-R01 — Large Transaction Detection
- **Typology:** Placement
- **Rationale:** Single large movements may represent placement of illicit funds.
- **Fields:** `Amount_Paid`, `From_Account`, `Timestamp`
- **Threshold:** `Amount_Paid >= 10,000`
- **Severity / Score:** High / 75
- **Escalation:** Auto-escalate; verify source of funds.
- **False positives:** Legitimate high rollers / verified VIPs. Mitigate with KYC
  risk level and player history.
- **Investigation guidance:** Confirm SOF documentation, KYC tier, prior pattern.

### AML-R02 — Structuring / Smurfing
- **Typology:** Placement / layering
- **Rationale:** Multiple deposits just under the reporting threshold to avoid detection.
- **Fields:** `Amount_Paid`, `From_Account`, `Timestamp`
- **Threshold:** ≥ 3 transactions in band **[9,000, 10,000)** by the same account within **7 days**
- **Severity / Score:** High / 80
- **Escalation:** Auto-escalate.
- **False positives:** Coincidental repeat amounts; payroll-like patterns. Mitigate
  with counterparty diversity check.
- **Investigation guidance:** Map the cluster timeline; check if amounts hug the threshold.

### AML-R03 — Rapid Movement of Funds
- **Typology:** Layering
- **Rationale:** Funds deposited and quickly withdrawn (pass-through) to obscure origin.
- **Fields:** inbound + outbound `Amount`, `Account`, `Timestamp`
- **Threshold:** Inbound followed by outbound **≥ 90%** of value within **6 hours** (same account)
- **Severity / Score:** High / 78
- **Escalation:** Auto-escalate.
- **False positives:** Legitimate cash-out after a win. Mitigate with gaming-activity correlation.
- **Investigation guidance:** Confirm whether gameplay occurred between in/out.

### AML-R04 — High Transaction Velocity
- **Typology:** Layering
- **Rationale:** Abnormally high transaction frequency suggests automated layering.
- **Fields:** `From_Account`, `Timestamp`
- **Threshold:** ≥ 8 transactions by the same account within **24 hours**
- **Severity / Score:** Medium / 60
- **Escalation:** Review queue.
- **False positives:** Active legitimate players. Mitigate with amount + win/loss context.
- **Investigation guidance:** Assess whether velocity matches normal play style.

### AML-R05 — Sub-Threshold Multiple Transactions
- **Typology:** Structuring (cumulative)
- **Rationale:** Many small transactions that individually evade review but aggregate high.
- **Fields:** `Amount_Paid`, `From_Account`, `Timestamp`
- **Threshold:** ≥ 5 transactions each `< 10,000` by the same account in **one day**
- **Severity / Score:** Medium / 55
- **Escalation:** Review queue.
- **False positives:** Micro-stakes players. Mitigate with daily aggregate floor.
- **Investigation guidance:** Sum the day's flow; compare to player norm.

### AML-R06 — High-Risk Payment Method
- **Typology:** Placement
- **Rationale:** Crypto and prepaid cards carry elevated ML risk, especially at value
  (cash is excluded — atypical for online gaming).
- **Fields:** `Payment_Format`, `Amount_Paid`
- **Threshold:** `Payment_Format IN ('Crypto','Prepaid Card')` AND `Amount_Paid >= 5,000`
- **Severity / Score:** Medium / 65
- **Escalation:** Review queue; escalate if combined with another rule.
- **False positives:** Legitimate crypto deposits. Mitigate with wallet/KYC checks.
- **Investigation guidance:** Trace funding instrument; confirm wallet ownership.

### AML-R07 — Unusual Activity Spike
- **Typology:** Behavioural anomaly
- **Rationale:** A sudden jump versus the account's own baseline can signal account takeover or mule use.
- **Fields:** `From_Account`, daily `Amount_Paid` total, `Timestamp`
- **Threshold:** Account's daily total **≥ 5×** its own median daily total **and ≥ 5,000**
- **Severity / Score:** Medium / 58
- **Escalation:** Review queue.
- **False positives:** One-off legitimate large play. Mitigate with multi-day persistence check.
- **Investigation guidance:** Compare spike day to trailing 30-day baseline.

### AML-R08 — Dormant Account Reactivation
- **Typology:** Account misuse
- **Rationale:** Long-dormant accounts suddenly transacting may indicate takeover or mule onboarding.
- **Fields:** `From_Account`, `Timestamp` gaps, `Amount_Paid`
- **Threshold:** Gap **≥ 30 days** since prior activity, then a transaction **≥ 5,000**
- **Severity / Score:** Medium / 62
- **Escalation:** Review queue.
- **False positives:** Seasonal players. Mitigate with re-KYC trigger.
- **Investigation guidance:** Re-verify identity; review login/device changes.

### AML-R09 — Round-Number Large Transactions
- **Typology:** Layering
- **Rationale:** Exact round thousands at value are atypical of organic play and common in layering.
- **Fields:** `Amount_Paid`
- **Threshold:** `Amount_Paid >= 10,000` AND `Amount_Paid` is an exact multiple of 1,000
- **Severity / Score:** Medium / 50
- **Escalation:** Review queue.
- **False positives:** Round legitimate transfers. Low individual weight; strengthens other rules.
- **Investigation guidance:** Use as corroborating signal alongside R01/R03.

### AML-R10 — Counterparty Concentration
- **Typology:** Layering / mule networks
- **Rationale:** Repeated high-value flow to a single external counterparty can indicate a mule or collusion ring.
- **Fields:** `From_Account`, `To_Account`, `Amount_Paid`
- **Threshold:** ≥ 4 transactions to the **same** `To_Account` totaling **≥ 20,000** within **30 days**
- **Severity / Score:** High / 72
- **Escalation:** Auto-escalate.
- **False positives:** Legitimate recurring payee. Mitigate with payee allow-listing.
- **Investigation guidance:** Map the account→counterparty network; check for rings.

### AML-R11 — Sanctions / Watchlist Match
- **Typology:** Sanctions screening
- **Rationale:** Any activity by a party matched to a sanctions or internal watchlist is
  reportable regardless of amount — a mandatory control, not a behavioural heuristic.
- **Fields:** `Sanctions_Flag` (from screening against the watchlist)
- **Threshold:** `Sanctions_Flag = 1` (any transaction)
- **Severity / Score:** Critical / 95
- **Escalation:** Immediate; freeze/review per policy.
- **False positives:** Name-match homonyms. Mitigate with secondary identity verification.
- **Investigation guidance:** Confirm the match, escalate to MLRO, consider freezing funds
  and filing the relevant report.

---

## 3b. Customer Risk Rating (CDD)

Beyond per-transaction alerts, each customer (player account) carries a risk rating —
the customer-due-diligence output a compliance team maintains:

| Rating | Criteria |
|---|---|
| Critical | Sanctions/watchlist match |
| High | PEP, or ≥ 3 alerted transactions |
| Medium | 1–2 alerted transactions |
| Low | No alerts, not PEP/sanctioned |

PEP status elevates risk but is **not** itself an alert (being a PEP is not a crime).
Implemented in the Phase 5 notebook; exported to `data_processed/account_risk_ratings.csv`.

---

## 4. Alert Output Structure

Each rule writes to `Fact_AML_Alerts` with:

| Field | Source |
|---|---|
| Transaction_Key | the triggering transaction |
| AlertType_Key | the rule (`Dim_AlertType`) |
| Account_Key / Player_Key | the subject account/player |
| Date_Key / Alert_Timestamp | when raised |
| Risk_Score / Severity | from scoring methodology |
| Status_Key | initial = `New` |
| Is_Escalated | 1 if score ≥ 70 |

---

## 5. Validation Approach

Because the dataset carries a ground-truth `Is_Laundering` label, the framework is
validated quantitatively (Phase 5 notebook):

- **Recall** — share of true laundering transactions flagged by ≥ 1 rule.
- **Precision** — share of flagged transactions that are truly laundering.
- **Per-rule precision** — how "clean" each rule's alerts are.
- **Confusion matrix** — TP / FP / FN / TN.

This mirrors how a real compliance team would tune thresholds to balance detection
against analyst workload (false positives).

> **Important validation caveat.** The transaction data is synthetic and the laundering
> typologies were *injected to match these rules*. As a result the measured recall and
> precision are **optimistic** and should be read as a demonstration that the rules
> correctly detect their intended patterns — **not** as expected production performance.
> On real data, lacking ground-truth labels and containing messier patterns, both
> metrics would be lower and the thresholds would require recalibration.

---

## 6. Implementation

- SQL implementation: [`/sql/aml_rules`](../sql/aml_rules)
- Python implementation + validation: [`/notebooks/02_aml_transaction_analysis.ipynb`](../notebooks/02_aml_transaction_analysis.ipynb)
