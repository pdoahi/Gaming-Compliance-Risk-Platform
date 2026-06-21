# Phase 3 — Database Architecture (Part 1)
## Gaming Compliance & Risk Intelligence Platform

This document explains the analytics database architecture that the SQL scripts in this folder implement. Scripts target **Microsoft SQL Server (T-SQL)**. A SQLite-compatible build can be generated for local execution where SQL Server is unavailable (noted in the project architecture blueprint).

---

## 1. OLTP vs OLAP

| Concern | This Platform |
|---|---|
| Purpose | **OLAP** — analytical reporting, AML monitoring, compliance dashboards |
| Source systems | OLTP-style transaction feeds (IBM AML data, simulated operator systems) |
| Write pattern | Bulk batch loads (ETL), not high-frequency single-row inserts |
| Read pattern | Aggregations, time-series, drill-through, joins across facts/dims |
| Schema style | Dimensional (star schema), not normalized 3NF |

The platform is an **analytics warehouse**, not a transactional system. Source OLTP data is landed, staged, transformed, and served for reporting.

---

## 2. Three-Layer Architecture

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   STAGING    │ --> │  ANALYTICS   │ --> │  REPORTING   │
│   LAYER      │     │  LAYER       │     │  LAYER       │
│ stg_* tables │     │ Dim_* Fact_* │     │ vw_* views   │
└──────────────┘     └──────────────┘     └──────────────┘
   raw landing          star schema          aggregated
   (1:1 w/ source)     (cleansed, keyed)     (business-ready)
```

### Staging Layer (`/sql/staging`)
- Tables prefixed `stg_`
- Mirror source structure as closely as possible (raw landing)
- No business logic; minimal typing
- Truncated and reloaded each batch
- Examples: `stg_Transactions`, `stg_MarketPerformance`

### Analytics Layer (`/sql/schema`)
- The star schema: 6 dimensions + 4 facts
- Surrogate keys, constraints, referential integrity, audit columns
- Populated from staging via ETL transformation logic
- This is the governed "single source of truth"

### Reporting Layer (`/sql/views`)
- Views prefixed `vw_`
- Pre-aggregated, business-friendly column names
- What Power BI and notebooks consume
- Shields BI tools from schema changes

---

## 3. Data Flow

```
Source CSV (synthetic AML + market series)
   │  (Python / bulk insert)
   ▼
stg_Transactions / stg_MarketPerformance      ← STAGING
   │  (ETL: lookups, surrogate keys, type casting, dedupe)
   ▼
Dim_* + Fact_*                                 ← ANALYTICS
   │  (aggregation, business rules)
   ▼
vw_* reporting views                           ← REPORTING
   │
   ▼
Power BI / Jupyter
```

---

## 4. Design Decisions

| Decision | Rationale |
|---|---|
| Surrogate integer keys on all dimensions | Decouples warehouse from volatile source IDs; faster joins |
| Audit columns (`CreatedDate`, `ModifiedDate`, `SourceSystem`) on every table | Lineage, troubleshooting, regulatory traceability |
| Staging layer kept separate | Isolates raw landing from cleansed analytics; safe reloads |
| Reporting via views, not direct table access | Stable contract for BI; logic centralized |
| `Is_Laundering` ground-truth label retained | Enables AML rule precision/recall validation in Phase 5 |
| `Fact_MarketPerformance` joined only to `Dim_Date` | Different grain (monthly) and source (market series); intentionally decoupled |

---

## 5. Object Inventory

| Layer | Folder | Objects |
|---|---|---|
| Schema | `/sql/schema` | 6 dimensions, 4 facts |
| Staging | `/sql/staging` | stg_Transactions, stg_MarketPerformance |
| Data Quality | `/sql/data_quality` | Transaction + market validation checks |
| Views | `/sql/views` | 5 reporting views |
| Test Data | `/sql/test_data` | Sample INSERTs for all facts + dims |
| Performance | `/sql/documentation` | Indexing & partitioning recommendations |

---

## 6. Recommended Execution Order

```
1. schema/01_create_dimensions.sql
2. schema/02_create_facts.sql
3. staging/03_staging_tables.sql
4. test_data/06_test_data.sql        (or real ETL load)
5. views/05_reporting_views.sql
6. data_quality/04_data_quality_checks.sql   (run anytime after load)
```
