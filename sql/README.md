# SQL — Database & Analytics Foundation (Phase 3)

Production-style SQL for the Gaming Compliance & Risk Intelligence Platform.
Scripts target **Microsoft SQL Server (T-SQL)**.

## Folder Layout

```
sql/
├── schema/         CREATE TABLE scripts (dimensions + facts)
├── staging/        Staging tables + ETL load procedures
├── data_quality/   Validation checks
├── views/          Reporting views (BI/notebook layer)
├── aml_rules/      Phase 5: AML rule views + alert generation
├── str_workflow/   Phase 6: status/analyst seed + STR KPI views
├── test_data/      Sample INSERTs for schema validation
└── documentation/  Architecture + performance notes
```

## Execution Order

| # | Script | Purpose |
|---|---|---|
| 1 | `schema/01_create_dimensions.sql` | 6 dimension tables |
| 2 | `schema/02_create_facts.sql` | 4 fact tables + FKs |
| 3 | `staging/03_staging_tables.sql` | Staging tables + load procs |
| 4 | `test_data/06_test_data.sql` | Sample data (or run real ETL) |
| 5 | `views/05_reporting_views.sql` | 5 reporting views |
| 6 | `data_quality/04_data_quality_checks.sql` | Validation (anytime after load) |

## Reference Docs

- [`documentation/00_database_architecture.md`](documentation/00_database_architecture.md) — three-layer architecture, OLTP/OLAP, data flow
- [`documentation/07_performance_optimization.md`](documentation/07_performance_optimization.md) — indexing, partitioning, maintenance

## Notes

- All synthetic data (`Dim_Player`, `Dim_Analyst`, `Dim_Status`, `Fact_STR_Cases`) is
  tagged `SourceSystem = 'Synthetic'`.
- For local execution without SQL Server, a SQLite-adapted build can be generated
  (T-SQL `IDENTITY`/`GETDATE()`/`BIT` map to SQLite equivalents). The logic and
  star-schema design are identical.
- AML rules (`Dim_AlertType` content + alert generation) are finalized in Phase 5.
