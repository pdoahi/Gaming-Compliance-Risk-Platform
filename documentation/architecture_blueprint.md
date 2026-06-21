# Phase 1 — Architecture Blueprint
## Gaming Compliance & Risk Intelligence Platform

---

## 1. Executive Summary

This document defines the architecture, business context, and delivery roadmap for the **Gaming Compliance & Risk Intelligence Platform** — a portfolio-grade analytics system that simulates the compliance, AML monitoring, and regulatory reporting functions of a regulated online gaming operator.

The platform is designed to demonstrate that its builder can:
- Analyze transaction data for AML risk using rule-based logic
- Manage a Suspicious Transaction Reporting (STR) case workflow end-to-end
- Report on online gaming market performance (GGR, wagers, active accounts)
- Deliver executive-level compliance and risk dashboards
- Apply Canadian regulatory context (FINTRAC) to analytics work

The project uses synthetic data that mirrors the IBM AML simulation schema, plus a synthetic market/GGR series. All data is fabricated for demonstration and clearly labelled throughout.

---

## 2. Business Context

### 2.1 Regulatory Environment

In a regulated online gaming market, licensed operators typically must comply with:

- **FINTRAC** (Financial Transactions and Reports Analysis Centre of Canada) obligations under the *Proceeds of Crime (Money Laundering) and Terrorist Financing Act*
- **regulator operator standards** for market conduct, reporting, and player protection
- **internet gaming technical standards** covering responsible gambling, AML controls, and system integrity

Operators are required to:
- Maintain AML compliance programs
- File Suspicious Transaction Reports (STRs) with FINTRAC when there are reasonable grounds to suspect money laundering or terrorist financing
- Report Large Cash Transactions (LCTs) over $10,000 CAD
- Conduct ongoing transaction monitoring

### 2.2 Business Problem

Gaming operators managing large transaction volumes face a critical operational challenge: **identifying suspicious activity at scale while meeting regulatory reporting timelines.** Without a structured analytics layer, compliance teams rely on manual reviews, fragmented spreadsheets, and reactive investigation — increasing regulatory risk and operational cost.

### 2.3 Business Case

This platform addresses that gap by providing:

| Capability | Business Value |
|---|---|
| Automated AML rule execution | Reduces manual review burden; prioritizes high-risk activity |
| STR case workflow management | Tracks investigations from alert to submission with SLA visibility |
| GGR and market performance reporting | Enables executive oversight and regulatory benchmarking |
| Integrated compliance dashboard | Gives leadership a single view of risk exposure and program health |

---

## 3. Stakeholders

| Stakeholder | Role | Interest in Platform |
|---|---|---|
| Chief Compliance Officer | Executive sponsor | AML program health, regulatory exposure, STR volumes |
| AML/Compliance Analysts | Primary users | Alert queue, case management, investigation workflow |
| Director of Compliance Analytics | Platform owner | Data quality, rule accuracy, dashboard reliability |
| Finance / GGR Reporting Team | Secondary users | Revenue reporting, market performance benchmarking |
| FINTRAC (external) | Regulator | Timely and accurate STR submissions |
| Gaming regulator (external) | Regulator | Operator performance reporting, market conduct |
| Internal Audit | Oversight | AML program effectiveness, SLA compliance |

---

## 4. Business & Compliance Objectives

### Business Objectives
- Demonstrate transaction monitoring capability across high-volume online gaming data
- Produce GGR and market performance reporting from the synthetic market series
- Enable executive-level visibility into compliance program performance

### Compliance Objectives
- Simulate a FINTRAC-aligned AML monitoring program
- Model an STR workflow from alert triage to regulatory submission
- Track SLA performance and case aging for compliance team accountability

### AML Objectives
- Apply 10 rule-based detection typologies relevant to online gaming transactions
- Generate risk-scored alerts with severity classifications
- Demonstrate escalation logic from alert → case → STR

---

## 5. Success Metrics

| Metric | Definition |
|---|---|
| Alert Coverage Rate | % of transactions reviewed by at least one AML rule |
| Escalation Rate | % of alerts escalated to case investigations |
| STR Conversion Rate | % of cases that result in an STR submission |
| SLA Compliance Rate | % of cases resolved within the defined SLA window |
| Average Investigation Time | Mean days from alert creation to case closure |
| GGR Reporting Accuracy | GGR values reconcile to the synthetic source series within rounding tolerance |
| Dashboard Load Reliability | All Power BI pages render without data model errors |

---

## 6. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        DATA SOURCES                             │
│  IBM AML-Data (CSV)    │    synthetic market data (CSV/Excel)      │
│  IBM AMLSim (CSV)      │    Synthetic STR/Case Data             │
└────────────┬───────────┴──────────────┬────────────────────────┘
             │                          │
             ▼                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      STAGING LAYER (SQL)                        │
│         stg_Transactions          stg_MarketPerformance         │
│         (raw load, no transforms)                               │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ANALYTICS LAYER (SQL)                        │
│  Dim_Date      Dim_Account    Dim_Player    Dim_AlertType       │
│  Dim_Status    Dim_Analyst                                      │
│  Fact_Transactions    Fact_AML_Alerts                           │
│  Fact_STR_Cases       Fact_MarketPerformance                    │
└──────────┬────────────────────────┬───────────────────────────┬─┘
           │                        │                           │
           ▼                        ▼                           ▼
┌──────────────────┐  ┌─────────────────────────┐  ┌──────────────────────┐
│  JUPYTER         │  │   SQL VIEWS / AML RULES  │  │  POWER BI            │
│  NOTEBOOKS       │  │   vw_AlertSummary        │  │  Executive Overview  │
│  Data exploration│  │   vw_STRSummary          │  │  AML Monitoring      │
│  AML analysis    │  │   vw_MarketPerformance   │  │  STR Workflow        │
│  GGR analysis    │  │   vw_ExecutiveMetrics    │  │  Market Performance  │
└──────────────────┘  └─────────────────────────┘  └──────────────────────┘
```

---

## 7. Data Flow

```
1. Raw CSVs land in /data_raw (never modified)
2. Jupyter notebooks load and clean raw data → export to /data_processed
3. SQL staging tables receive processed data
4. ETL logic transforms staging into dimension and fact tables
5. AML rule views execute against Fact_Transactions → populate Fact_AML_Alerts
6. Analyst workflow populates Fact_STR_Cases from escalated alerts
7. Reporting views aggregate all four fact tables
8. Power BI connects to reporting views → renders dashboards
```

---

## 8. Technology Stack

| Layer | Technology | Rationale |
|---|---|---|
| Data storage | SQL Server (or SQLite for local dev) | Industry standard for analytics warehouses |
| Data processing | Python 3, pandas, numpy | Standard data science stack |
| Notebooks | Jupyter | Explainable, shareable analysis |
| AML rules | SQL views + insert logic | Transparent, auditable, version-controlled |
| Dashboards | Power BI Desktop | Industry-standard BI tool for compliance reporting |
| Version control | GitHub | Public portfolio, commit history as evidence of work |
| AI assistance | Claude (design) + Cursor (implementation) | Accelerated, phase-controlled development |

---

## 9. Risks & Assumptions

### Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| IBM AML dataset structure differs from expected schema | Medium | High | Review dataset README before Phase 3; adapt staging logic accordingly |
| Market-data source format changes if real data is later substituted | Low | Medium | Lock down the schema; keep the synthetic generator as the reference |
| SQL Server not available locally | Medium | Medium | Use SQLite as a fallback; note the difference in documentation |
| Power BI licensing limitations | Low | Low | Power BI Desktop is free; .pbix export is sufficient for portfolio |
| Synthetic data looks unrealistic | Medium | High | Use IBM data as the base; limit synthetic additions to case metadata only |

### Assumptions

- IBM AML-Data transactions represent a plausible online gaming transaction profile for AML purposes
- the synthetic market series is generated deterministically — figures are illustrative, not real
- All synthetic data is clearly labelled as synthetic in documentation and notebooks
- The project does not submit real STRs to FINTRAC — this is a simulation only
- SQL Server syntax is targeted; SQLite adaptations are noted where relevant

---

## 10. Project Roadmap

| Phase | Deliverable | Tool | Output Path |
|---|---|---|---|
| 1 | Architecture Blueprint | Claude | `documentation/architecture_blueprint.md` |
| 2 | Data Model (Star Schema) | Claude | `documentation/data_model.md` |
| 3 | SQL Database Foundation | Cursor | `/sql/schema`, `/sql/staging`, `/sql/views` |
| 4 | Jupyter Data Exploration | Jupyter | `/notebooks/01_data_exploration.ipynb` |
| 5 | AML Monitoring Framework | Claude → Cursor | `/sql/aml_rules`, `/notebooks/02_aml_transaction_analysis.ipynb` |
| 6 | STR Workflow | Claude → Cursor | `Fact_STR_Cases`, `/notebooks/03_str_workflow_simulation.ipynb` |
| 7 | GGR Reporting | Jupyter | `/notebooks/04_market_ggr_analysis.ipynb` |
| 8 | Power BI Dashboards | Power BI | `/powerbi/pbix`, `/screenshots` |
| 9 | Portfolio Documentation | Claude | `README.md`, `/documentation/final_report.md` |
| 10 | Director Review & Polish | Claude | Final improvement list |

---

## 11. Recommended Next Phase

**Phase 2 — Data Model Design**

Design the star schema that underpins all four reporting areas. Define every dimension and fact table, their columns, keys, relationships, and data sources before any SQL is written.

Prompt file: [`ai_prompts/02_Data_Model_Design.md`](ai_prompts/02_Data_Model_Design.md)
