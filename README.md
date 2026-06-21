# Gaming Compliance & Risk Intelligence Platform

> An end-to-end compliance analytics platform simulating AML transaction monitoring,
> STR case management, and online gaming market (GGR) reporting for a regulated
> online gaming operator — built with SQL, Python/Jupyter, and Power BI.

---

## Executive Summary

This project demonstrates how a compliance and risk analytics function for a
regulated online gaming operator can be designed and delivered end to end. It
combines **anti-money-laundering (AML) transaction monitoring**, a **Suspicious
Transaction Report (STR) case workflow**, and **online gaming Gross Gaming Revenue (GGR)
market reporting** into a single, documented platform with an executive dashboard layer.

The AML monitoring engine implements **11 rule-based typologies** (including sanctions
/ watchlist screening) plus a customer risk rating. On labelled **synthetic** data it
reaches **99% recall and 87% precision (F1 = 0.93)** — an optimistic, demonstrative
result (see the validation caveat under Limitations). A logistic-regression ML baseline
(ROC-AUC ≈ 0.98) is included to show a hybrid rules-plus-ML approach. Escalated alerts
flow into a simulated STR case workflow with SLAs, analyst workload, and KPI tracking.
The market-reporting layer uses a **fabricated 48-month online-gaming market series**
(synthetic wagers, GGR, active accounts, and ARPPA) so the GGR dashboards have
realistic-looking trends to chart — the figures are illustrative only.

The work is structured as a 10-phase delivery — architecture, data model, SQL
foundation, data exploration, AML rules, STR workflow, GGR reporting, dashboards,
documentation, and review — mirroring how a real analytics initiative is run.

---

## Business Problem

In a regulated online gaming market, licensed operators must run AML programs and file
STRs with their financial-intelligence regulator (in Canada, **FINTRAC**) when they have
reasonable grounds to suspect money laundering or terrorist financing. At scale — large
volumes wagered every month — operators cannot rely on manual review. They need a
structured analytics layer that:

- monitors transactions for suspicious patterns,
- prioritizes alerts by risk,
- manages investigations to regulatory timelines, and
- gives leadership visibility into both market performance and compliance health.

This platform addresses that need.

---

## Project Objectives

1. Detect AML risk in transaction data using explainable, rule-based logic.
2. Score and escalate alerts; route them into an investigation workflow.
3. Manage STR cases with statuses, SLAs, audit trail, and KPIs.
4. Report online gaming market performance (wagers, GGR, active accounts) on synthetic data.
5. Present everything through executive-grade dashboards.
6. Document the work to a professional, regulator-ready standard.

---

## Data Sources

| Source | Type | Use |
|---|---|---|
| Synthetic AML transactions (generator in repo) | Synthetic, IBM-AML schema | AML monitoring & STR workflow |
| Synthetic market / GGR series (generator in repo) | Synthetic, illustrative | GGR / market reporting |

**Why synthetic AML data?** Real transaction-monitoring data is customer PII and would
never appear in a public repository — using clearly-labelled synthetic data is the
correct professional choice and is standard practice for compliance system testing.
The generator (`data_raw/synthetic_data_generator.py`) mirrors the IBM *Transactions
for AML* schema, so a real dataset can be dropped in unchanged. The market / GGR series
is **also synthetic**, produced by the same generator and clearly labelled as
illustrative — it does not represent any real market.

---

## Solution Architecture

```
   Synthetic AML transactions          Synthetic market / GGR series (.csv)
              │                                      │
              ▼                                      ▼
        ┌───────────── STAGING (SQL) ──────────────┐
        │  stg_Transactions     stg_MarketPerf      │
        └───────────────────┬───────────────────────┘
                            ▼
        ┌──────────── ANALYTICS (SQL star schema) ──┐
        │ Dim_Date Dim_Account Dim_Player           │
        │ Dim_AlertType Dim_Status Dim_Analyst      │
        │ Fact_Transactions Fact_AML_Alerts         │
        │ Fact_STR_Cases Fact_MarketPerformance     │
        └──────┬───────────────┬─────────────┬──────┘
               ▼               ▼             ▼
        Jupyter notebooks  SQL views    Power BI
        (explore, AML,    (reporting)   (4 dashboards)
         STR, GGR)
```

Three layers — **staging → analytics (star schema) → reporting** — feed Jupyter
notebooks (analysis & validation) and a Power BI dashboard layer. Full detail in
[`documentation/architecture_blueprint.md`](documentation/architecture_blueprint.md).

---

## Data Model

A star schema with conformed dimensions and an explicit grain per fact, mirroring the
AML escalation lifecycle **Transaction → Alert → Case**:

- **Dimensions:** Date, Account, Player, AlertType, Status, Analyst
- **Facts:** Transactions, AML_Alerts, STR_Cases, MarketPerformance

Every column is tagged Source / Derived / Synthetic. Full data dictionary in
[`documentation/data_model.md`](documentation/data_model.md); SQL implementation in
[`sql/`](sql) (schema, staging, data-quality, views, AML rules, STR KPIs).

---

## AML Monitoring Framework

**11 explainable rules** spanning placement, structuring, layering, behavioural, and
sanctions typologies — each with a documented rationale, threshold, risk score,
severity, and false-positive considerations, plus a customer risk rating (CDD)
([`documentation/aml_monitoring_framework.md`](documentation/aml_monitoring_framework.md)):

R01 Large Transaction · R02 Structuring · R03 Rapid Movement · R04 High Velocity ·
R05 Sub-Threshold Multiple · R06 High-Risk Payment Method · R07 Activity Spike ·
R08 Dormant Reactivation · R09 Round-Number · R10 Counterparty Concentration ·
R11 Sanctions / Watchlist Match

Implemented in SQL ([`sql/aml_rules`](sql/aml_rules)) and validated in Python
([`notebooks/02_aml_transaction_analysis.ipynb`](notebooks/02_aml_transaction_analysis.ipynb))
against the ground-truth label (synthetic data — see caveat under Limitations):

| Metric | Result |
|---|---|
| Recall | **99.4%** |
| Precision | **86.9%** |
| F1 | **0.927** |

A logistic-regression baseline ([`notebooks/05_ml_baseline.ipynb`](notebooks/05_ml_baseline.ipynb))
reaches ROC-AUC ≈ 0.98 on behavioural features, supporting a hybrid rules-plus-ML approach.

---

## STR Workflow

Escalated alerts (risk ≥ 70) become investigation cases moving through
**New → Under Review → Escalated → STR Submitted → Closed**, with SLAs by priority,
audit-trail requirements, closure reasons, and QA review points
([`documentation/str_workflow.md`](documentation/str_workflow.md)). Simulated and
measured in [`notebooks/03_str_workflow_simulation.ipynb`](notebooks/03_str_workflow_simulation.ipynb):

| KPI | Value |
|---|---|
| Total cases | 362 |
| Open backlog | 184 |
| STRs filed | 207 |
| STR conversion rate | 57.2% |
| Avg investigation time | 5.0 days |
| SLA compliance | 93.8% |

STR conversion correctly tracks ground truth (62% for true laundering vs ~0% for
false positives) — the discriminating behaviour real investigations produce.

---

## online gaming GGR Reporting (synthetic data)

A fabricated 48-month market series
([`notebooks/04_market_ggr_analysis.ipynb`](notebooks/04_market_ggr_analysis.ipynb)),
illustrative only:

| Fiscal Year | Wagers | GGR | YoY |
|---|---|---|---|
| FY23 (yr 1) | $9.4B | $0.37B | — |
| FY24 (yr 2) | $14.0B | $0.54B | +44% |
| FY25 (yr 3) | $20.5B | $0.82B | +53% |
| FY26 (yr 4) | $23.0B | $0.89B | +8% |

These are generated figures, not a real market. Built-in patterns to demonstrate the
reporting: ~3x monthly GGR growth across the series, a stable ~4% hold, and Casino at
~66% of revenue.

---

## Dashboards (Power BI)

Four pages — **Executive Overview, AML Monitoring, STR Workflow, online gaming Market
Performance** — fully specified in
[`documentation/dashboard_specification.md`](documentation/dashboard_specification.md),
with DAX measures, Power Query, model relationships, and a build guide in
[`powerbi/`](powerbi). The `.pbix` is assembled in Power BI Desktop; screenshots will
be added to [`screenshots/`](screenshots) per the
[checklist](powerbi/documentation/screenshot_checklist.md).

---

## Key Findings

- A transparent, **rule-based AML engine** detects every injected typology while keeping
  each alert explainable to an investigator and a regulator (F1 = 0.93 on labelled
  synthetic data; see caveat). Sanctions screening is enforced as a mandatory control.
- Two signals dominate detection in this dataset: **large transactions (>$10k)** and
  the **$9k–$10k structuring band**; Cash and Crypto are over-represented in flags.
- The **STR workflow** turns raw alerts into a managed, SLA-tracked pipeline; STR
  conversion cleanly separates true suspicion from false positives.
- the synthetic market series shows ~**3x** monthly GGR growth across the window with a
  stable hold — illustrating a maturing-market narrative for the dashboards.

---

## Skills Demonstrated

- **Compliance / AML domain:** FINTRAC STR process, AML typologies, sanctions/watchlist
  screening, customer risk rating (CDD), risk scoring, SLA-driven case management.
- **SQL:** star-schema design, constraints, staging/ETL, data-quality framework,
  reporting views, AML rule logic (SQL Server T-SQL).
- **Python / Jupyter:** data cleaning, rule implementation, model validation
  (precision/recall/F1, ROC-AUC), ML baseline (scikit-learn logistic regression),
  simulation, visualization (pandas, numpy, matplotlib).
- **Data modeling & BI:** dimensional modeling, Power BI data model, DAX, dashboard design.
- **Engineering practice:** reproducible pipeline, real-data sourcing & reconciliation,
  Git version control, professional documentation.

---

## Limitations

- **Validation is optimistic by construction.** AML data is synthetic and the laundering
  typologies were *injected to match the rules*, so the 99% recall / 87% precision figures
  demonstrate that the rules detect their intended patterns — they are **not** expected
  production performance. On real, unlabelled, messier data both metrics would be lower
  and thresholds would need recalibration. The same caveat applies to the ML baseline.
- All datasets — AML transactions, STR case metadata, and the market/GGR series — are
  **synthetic** (clearly labelled) and represent no real customers or market.
- The schema/rule **SQL is written for SQL Server and was not executed against a live
  server** in this environment. The relational schema/constraints/views were verified via
  a SQLite build; the AML-rule logic was validated through the Python implementation,
  which mirrors the SQL. Treat the SQL as designed-and-logic-validated, not production-run.
- Detection is primarily **rule-based** (with an ML baseline for comparison); a real
  deployment would add tuned ML and ongoing threshold calibration.
- The Power BI `.pbix` is assembled from the provided package in Power BI Desktop.

---

## Future Enhancements

- Add **ML / anomaly-detection** models alongside the rules and compare performance.
- **Network analysis** for circular-flow and mule-ring detection.
- **SCD Type 2** history on dimensions (player risk, KYC status over time).
- Orchestration (dbt / Airflow) and a real warehouse deployment.
- Near-real-time streaming alerts and automated STR-filing integration.

---

## Repository Guide

```
documentation/   Architecture, data model, AML framework, STR workflow, dashboard spec
sql/             Schema, staging, data quality, views, AML rules, STR KPIs
notebooks/       01 exploration · 02 AML · 03 STR · 04 GGR · 05 ML baseline
data_raw/        Synthetic generator + generated AML & market CSVs
data_processed/  Cleaned, analytics-ready datasets
powerbi/         DAX, model, Power Query, build guide, screenshot checklist
ai_prompts/      Phase-by-phase prompts used to guide development
```

### Reproduce locally
```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python data_raw/synthetic_data_generator.py        # regenerate AML data
jupyter notebook                                    # run notebooks 01–04
```

---

## Project Status

| Phase | Deliverable | Status |
|---|---|---|
| 1 | Architecture Blueprint | ✅ |
| 2 | Data Model Design | ✅ |
| 3 | SQL Database Foundation | ✅ |
| 4 | Jupyter Data Exploration | ✅ |
| 5 | AML Monitoring Framework | ✅ |
| 6 | STR Workflow Management | ✅ |
| 7 | online gaming GGR Reporting (synthetic data) | ✅ |
| 8 | Power BI Dashboards | 📋 Build package ready (assemble .pbix) |
| 9 | Portfolio Documentation | ✅ |
| 10 | Director Review & remediation | ✅ |

---

## License & Data Attribution

- Code and documentation: **MIT License** (see [`LICENSE`](LICENSE)).
- All data — AML, STR, and the market/GGR series — is **synthetic**, generated by this
  repo, and contains no real customer or market information. See
  [`DATA_ATTRIBUTION.md`](DATA_ATTRIBUTION.md).

> **Disclaimer.** This is an independent portfolio project built on synthetic and
> public, open-source data. It is not affiliated with, endorsed by, or representative
> of any regulator, gaming authority, or operator, and uses no proprietary or internal
> company information.

---

*Built as a portfolio project. Every dataset is synthetic and clearly labelled
throughout — the figures are illustrative and represent no real market.*
