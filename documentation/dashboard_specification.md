# Phase 8 — Power BI Dashboard Specification
## Gaming Compliance & Risk Intelligence Platform

Four dashboard pages. This spec drives the build in [`/powerbi`](../powerbi). It is
tool-agnostic design; the DAX, Power Query, and model wiring live in `/powerbi`.

---

## Data Sources (import from `data_processed/` and `data_raw/`)

| Table (Power BI) | File | Grain |
|---|---|---|
| Transactions | `data_processed/transactions_clean.csv` | one row / transaction |
| AML_Alerts | `data_processed/aml_alerts.csv` | one row / (transaction × rule) |
| STR_Cases | `data_processed/str_cases.csv` | one row / case |
| Market | `data_processed/market_performance_clean.csv` | one row / month |
| Market_Product | `data_raw/market_by_product_synthetic.csv` | one row / (month × product) |
| Date | generated (DAX `CALENDAR`) | one row / day |

---

## Page 1 — Executive Overview

**Audience:** Chief Compliance Officer, board, senior leadership.
**Business questions:** How is the market performing and is the compliance program healthy?

**KPI cards:** Total Wagers, Total GGR, Active Player Accounts, AML Alerts, STRs Submitted, Escalation Rate, Open Investigations, SLA Compliance %.

**Charts:**
- GGR trend line (Market, by month)
- AML alerts by month (AML_Alerts)
- Case status funnel (STR_Cases)
- Hold % gauge / card

**Filters/slicers:** Date (fiscal year, month), Severity.
**Drill-through:** from "AML Alerts" card → AML Monitoring page; from "STRs" card → STR Workflow page.
**User story:** *As a CCO, I want one screen that shows market scale and program health so I can brief the board.*
**Executive insight callout:** GGR growth %, escalation rate vs prior period.

---

## Page 2 — AML Monitoring

**Audience:** AML analysts, financial-crime team lead.
**Business questions:** What is firing, how severe, and which accounts are risky?

**KPI cards:** Total Alerts, Escalated Alerts, Escalation Rate, Avg Risk Score, High-Risk Accounts.

**Charts:**
- Alerts by rule (bar, AML_Alerts.Rule_Name)
- Alerts by severity (stacked column by month)
- Risk score distribution (histogram)
- Top 10 accounts by alert count (bar, From_Account)
- Transaction trend with flagged overlay

**Filters:** Date, Rule, Severity, Payment Format.
**Drill-through:** account → account detail (all alerts + transactions for that account).
**User story:** *As an AML analyst, I want to triage today's alerts by severity and rule so I work the riskiest first.*
**Insight callout:** rule with highest volume; rule with best precision (link to notebook validation).

---

## Page 3 — STR Workflow

**Audience:** AML operations manager, MLRO.
**Business questions:** Where are cases in the pipeline, are we within SLA, and how is workload distributed?

**KPI cards:** Total Cases, Open Backlog, STRs Filed, STR Conversion %, Avg Investigation Days, SLA Compliance %.

**Charts:**
- Cases by status (funnel / column, ordered New→Closed)
- Analyst workload (clustered bar: total / open / STRs)
- Case aging buckets (column, open cases)
- SLA compliance (within vs breached)
- STR conversion by priority

**Filters:** Status, Analyst, Priority, Date (open date).
**Drill-through:** case → case detail (closure reason, dates, SLA).
**User story:** *As an ops manager, I want to see backlog and SLA breaches so I can rebalance the team.*
**Insight callout:** backlog count; oldest open case age.

---

## Page 4 — online gaming Market Performance

**Audience:** Finance, market strategy, executives.
**Business questions:** How are wagers, GGR, and the player base trending, and by product?

**KPI cards:** Total Wagers, Total GGR, Hold %, Active Accounts, ARPPA, GGR YoY %.

**Charts:**
- Wagers vs GGR over time (dual axis, Market)
- GGR by product category (stacked area, Market_Product)
- Product GGR share (donut, latest month)
- Active accounts + ARPPA trend
- Fiscal-year GGR with YoY labels

**Filters:** Fiscal Year, Product Category, Date.
**Drill-through:** month → month detail.
**User story:** *As finance, I want GGR and hold trends by product so I can track revenue quality.*
**Insight callout:** latest GGR YoY %; casino share of GGR.

---

## Recommended Interactions

- Cross-filtering ON within each page (clicking a bar filters the page).
- Card-level drill-through between pages (Executive → detail pages).
- Consistent slicer panel (Date + Severity) synced across AML/STR pages.
- Tooltips show rule description / closure reason on hover.

## Theme

- Severity colors: Low `#16a34a`, Medium `#ca8a04`, High `#ea580c`, Critical `#dc2626`.
- Primary `#2563eb`; neutral grays for backgrounds. Consistent across all pages.
