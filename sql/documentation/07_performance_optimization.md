# Phase 3 — Performance Optimization (Part 6)
## Gaming Compliance & Risk Intelligence Platform

Recommendations for keeping the analytics warehouse performant as transaction
volume grows. Rationale is included for each so reviewers can see the reasoning.

---

## 1. Clustered Indexes

| Table | Clustered On | Rationale |
|---|---|---|
| Dim_Date | Date_Key | Natural integer key; range scans by date are common |
| Fact_Transactions | Transaction_Key | Surrogate PK; stable, ever-increasing → minimal page splits |
| Fact_AML_Alerts | Alert_Key | Same — monotonic insert pattern |
| Fact_MarketPerformance | MarketPerf_Key | Small table; PK clustering is sufficient |

All PKs above are already `CLUSTERED` in the schema scripts.

---

## 2. Non-Clustered Indexes

Add these to support the most common query/join patterns:

```sql
-- Date-range filtering and joins on facts
CREATE NONCLUSTERED INDEX IX_FactTxn_DateKey      ON dbo.Fact_Transactions (Date_Key) INCLUDE (Amount, Transaction_Direction);
CREATE NONCLUSTERED INDEX IX_FactTxn_AccountKey   ON dbo.Fact_Transactions (Account_Key);
CREATE NONCLUSTERED INDEX IX_FactAlert_DateKey    ON dbo.Fact_AML_Alerts (Date_Key) INCLUDE (Risk_Score, Is_Escalated);
CREATE NONCLUSTERED INDEX IX_FactAlert_TypeKey    ON dbo.Fact_AML_Alerts (AlertType_Key);
CREATE NONCLUSTERED INDEX IX_FactAlert_StatusKey  ON dbo.Fact_AML_Alerts (Status_Key);
CREATE NONCLUSTERED INDEX IX_FactCase_StatusKey   ON dbo.Fact_STR_Cases (Status_Key) INCLUDE (SLA_Breached, STR_Submitted_Flag);
CREATE NONCLUSTERED INDEX IX_FactCase_AnalystKey  ON dbo.Fact_STR_Cases (Analyst_Key);
```

**Rationale:** Star-schema queries filter facts by date and join to dimensions on
their keys. Indexing the FK columns avoids full table scans; `INCLUDE` columns make
the most common aggregations covering (no key lookups).

---

## 3. Partitioning Strategy

For high-volume `Fact_Transactions` and `Fact_AML_Alerts`:

- **Partition by month** on `Date_Key` using a partition function/scheme.
- Benefits: partition elimination on date-filtered queries, faster loads (switch-in),
  easier archiving of old periods.

```sql
-- Illustrative: monthly partition function on Date_Key (YYYYMMDD)
-- CREATE PARTITION FUNCTION pf_Month (INT) AS RANGE RIGHT
--   FOR VALUES (20240101, 20240201, 20240301, ...);
```

Partitioning is optional for a portfolio dataset but documented to show awareness.

---

## 4. View Optimization

- Keep reporting views **non-nested** where possible (avoid views on views).
- For very large aggregations, consider **indexed views** (`WITH SCHEMABINDING`) on
  `vw_AlertSummary` / `vw_TransactionSummary` to materialize the aggregate.
- The executive view uses CTEs with pre-grouped subqueries to limit the working set
  before the final join.

---

## 5. Query Optimization Practices

- Filter on `Date_Key` (integer) rather than casting `Transaction_Timestamp`.
- Avoid `SELECT *` in production queries; project only needed columns.
- Use `EXISTS` instead of `IN` for large subqueries (see ETL idempotency checks).
- Keep statistics current: `UPDATE STATISTICS` after large loads.
- Review actual execution plans for the four dashboard queries before go-live.

---

## 6. Maintenance

| Task | Frequency |
|---|---|
| Rebuild/reorganize indexes | Weekly or by fragmentation % |
| Update statistics | After each major ETL load |
| Review DQ check results | Every batch |
| Archive partitions older than retention policy | Quarterly |
