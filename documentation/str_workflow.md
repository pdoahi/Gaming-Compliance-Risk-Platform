# Phase 6 — STR Workflow Management
## Gaming Compliance & Risk Intelligence Platform

---

## 1. Overview

Escalated AML alerts (risk score ≥ 70) become **investigation cases**. This document
defines the Suspicious Transaction Report (STR) case management workflow: statuses,
fields, SLAs, audit trail, closure reasons, QA, and KPIs. In Canada, confirmed
suspicion is reported to **FINTRAC** as an STR.

```
   AML Alert (escalated)
        │
        ▼
   [ New ] ──▶ [ Under Review ] ──▶ [ Escalated ] ──▶ [ STR Submitted ] ──▶ [ Closed ]
                     │                                                          ▲
                     └──────────────── (no suspicion confirmed) ───────────────┘
```

---

## 2. Status Definitions

| Status | Category | Meaning | Next steps |
|---|---|---|---|
| **New** | Open | Case created from an escalated alert; unassigned/just assigned | Triage, assign analyst |
| **Under Review** | Open | Analyst actively investigating | Gather evidence, decide |
| **Escalated** | Open | Raised to senior analyst / MLRO for decision | Decide STR vs close |
| **STR Submitted** | Open | STR filed with FINTRAC; awaiting administrative closure | Record reference, close |
| **Closed** | Closed | Terminal state (STR filed, or no suspicion confirmed) | None |

---

## 3. Required Case Fields (`Fact_STR_Cases`)

| Field | Purpose | Source |
|---|---|---|
| Case_Key | Surrogate PK | Derived |
| Alert_Key | Originating escalated alert | FK → Fact_AML_Alerts |
| Analyst_Key | Assigned investigator | FK → Dim_Analyst (synthetic) |
| Player_Key | Subject of investigation | FK → Dim_Player |
| Status_Key | Current workflow status | FK → Dim_Status |
| Open_Date_Key | Case creation date | Derived from alert |
| Close_Date_Key | Case closure date (null if open) | Synthetic |
| Case_Priority | Low/Medium/High/Critical | From alert severity |
| SLA_Days | Target resolution window | By priority |
| Investigation_Days | Actual days to close (or days open) | Derived |
| SLA_Breached | 1 if exceeded SLA | Derived |
| STR_Submitted_Flag | 1 if STR filed | Synthetic |
| Closure_Reason | Why the case closed | Synthetic |

---

## 4. Investigation Notes Structure

Each case maintains an append-only investigation log (modeled as a child table in a
full build; simulated as structured text here):

```
[timestamp] [analyst] [action] [note]
2024-04-02 09:14  AN-007  TRIAGE     Alert R02 structuring, 5 deposits 9,200–9,800 over 3 days
2024-04-02 14:30  AN-007  REVIEW     KYC tier 2; no SOF on file; requested documentation
2024-04-04 11:02  AN-011  ESCALATE   Pattern consistent with smurfing; escalating to MLRO
2024-04-05 16:45  AN-003  DECISION   STR warranted; filed FINTRAC ref STR-2024-000142 (synthetic)
```

---

## 5. SLA Definitions

SLA target resolution time by case priority:

| Priority | SLA (days) | Rationale |
|---|---|---|
| Critical | 5 | Highest ML risk; regulatory exposure |
| High | 10 | Standard escalated case |
| Medium | 15 | Lower-severity review |
| Low | 20 | Monitoring/administrative |

**SLA_Breached** = resolution time (or current age for open cases) exceeds the target.

---

## 6. Escalation Rules

- Alerts with risk score **≥ 70** auto-create cases (set in Phase 5).
- Cases unresolved beyond **50% of SLA** are surfaced for supervisor review.
- **Critical** cases and any case touching a **PEP** route directly to the MLRO.
- A case combining **≥ 3 distinct rules** on one subject auto-escalates priority.

---

## 7. Audit Trail Requirements

Every state change records: who, what, when, and why. Required for FINTRAC
examination and internal audit:
- Immutable, append-only event log per case
- Analyst identity on every action
- Timestamped status transitions
- Decision rationale captured at closure
- STR reference number retained when filed

---

## 8. Case Closure Reasons

| Closure Reason | STR filed? |
|---|---|
| STR filed with FINTRAC | Yes |
| No suspicious activity confirmed (false positive) | No |
| Insufficient evidence — monitor | No |
| Duplicate / consolidated into another case | No |

---

## 9. Quality Assurance Review Points

- **Pre-filing QA:** senior review of every STR before submission.
- **Sample QA:** 10% of closed-no-STR cases re-reviewed to catch missed suspicion.
- **SLA QA:** weekly review of breached and aging cases.
- **Calibration:** monthly review of rules with low precision (high false positives).

---

## 10. STR Workflow KPIs

| KPI | Definition |
|---|---|
| Alert Volume | Total AML alerts generated |
| Escalation Rate | Escalated alerts ÷ total alerts |
| STR Conversion Rate | STRs filed ÷ total cases |
| Backlog | Count of open (non-terminal) cases |
| Average Investigation Time | Mean days to close (closed cases) |
| SLA Compliance Rate | Cases resolved within SLA ÷ resolved cases |
| Cases by Analyst | Workload distribution |
| Cases by Status | Funnel / pipeline view |
| Aging Open Cases | Open cases bucketed by days open |

---

## 11. Implementation

- SQL: [`/sql/str_workflow`](../sql/str_workflow) — status/analyst seed, case generation guidance, KPI views
- Simulation + KPIs: [`/notebooks/03_str_workflow_simulation.ipynb`](../notebooks/03_str_workflow_simulation.ipynb)
- Output dataset: `data_processed/str_cases.csv`

> All case-level data (analysts, statuses, dates, closure reasons) is **synthetic**,
> clearly labelled, and integrated with the real (synthetic) alert data from Phase 5.
