# Power BI Data Model

How to wire the imported tables. Goal: a clean star-style model with a single
**Date** dimension driving the time-based visuals.

## Tables

| Table | Type | Source |
|---|---|---|
| Date | Dimension | DAX `CALENDAR` (see dax/00_date_table.dax) |
| Transactions | Fact | transactions_clean.csv |
| AML_Alerts | Fact | aml_alerts.csv |
| STR_Cases | Fact | str_cases.csv |
| Market | Fact (monthly) | market_performance_clean.csv |
| Market_Product | Fact (monthly×product) | market_by_product_synthetic.csv |

## Relationships

```
Date[Date] 1───* Transactions[Timestamp_Date]
Date[Date] 1───* AML_Alerts[Timestamp_Date]
Date[Date] 1───* STR_Cases[Open_Date]
Date[Date] 1───* Market[Date]
Date[Date] 1───* Market_Product[Date]
```

- All fact↔Date relationships are **single-direction** (Date filters facts).
- `AML_Alerts[Transaction_ID]` → `Transactions[Transaction_ID]` (many-to-one,
  single direction) for alert↔transaction drill-through.
- `STR_Cases[Transaction_ID]` → `Transactions[Transaction_ID]` likewise.
- Market and Market_Product join the model **only through Date** (different grain
  from the AML facts — do not relate them to Transactions).

## Notes / gotchas

- **Add `Transaction_ID` to Transactions** in Power Query (an Index column starting
  at 0) so it matches the `Transaction_ID` already present in AML_Alerts / STR_Cases
  (those were created from the transaction row index in the notebooks).
- Create a date-only column on the timestamp facts (`Timestamp_Date`) for the Date
  relationship; keep the full timestamp for hour-level analysis.
- Mark the **Date** table as a Date Table (Power BI: Table tools → Mark as date table).
- Hide raw key/helper columns from the report view to keep the field list clean.

## Naming conventions

- Tables: PascalCase singular-ish (Transactions, AML_Alerts, STR_Cases, Market, Date).
- Measures: Title Case with spaces ("Total GGR", "Escalation Rate %"), stored in a
  dedicated `_Measures` table.
- Columns: keep source names; rename only for clarity in tooltips.
