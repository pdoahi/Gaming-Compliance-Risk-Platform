# Power BI Build Guide

Step-by-step to assemble the `.pbix` from the data products. Everything except the
final clicking-together is pre-written in `/powerbi`.

## Prerequisites
- Power BI Desktop (free) — Windows.
- This repo cloned locally; notebooks already run so `data_processed/` is populated.

## Steps

1. **New file** in Power BI Desktop. Save as `powerbi/pbix/Gaming_Compliance.pbix`.
2. **Parameter:** Home → Transform data → Manage Parameters → add `RepoPath` = your repo root.
3. **Load tables:** for each query in [`../model/power_query_steps.md`](../model/power_query_steps.md),
   New Source → Blank Query → Advanced Editor → paste → Close & Apply.
   Loads: Transactions, AML_Alerts, STR_Cases, Market, Market_Product.
4. **Date table:** Modeling → New table → paste [`../dax/00_date_table.dax`](../dax/00_date_table.dax).
   Then Table tools → Mark as date table → `Date[Date]`.
5. **Relationships:** wire per [`../model/data_model.md`](../model/data_model.md) (Model view).
6. **Measures:** create a `_Measures` table (Enter Data, one dummy column, delete it),
   then add every measure from `../dax/01–03_*.dax`.
7. **Build the 4 pages** per [`../../documentation/dashboard_specification.md`](../../documentation/dashboard_specification.md):
   Executive Overview, AML Monitoring, STR Workflow, online gaming Market Performance.
8. **Apply theme** (severity colors in the spec). View → Themes → customize.
9. **Drill-through:** add a drill-through page per the spec (account / case / month).
10. **Export screenshots** per [`screenshot_checklist.md`](screenshot_checklist.md) into `../../screenshots/`.
11. **Save** the `.pbix` into `../pbix/` and commit.

## Tips

- Use the measures, not implicit aggregations, on cards/visuals.
- Format `Total GGR` / `Total Wagers` as currency; `Hold %`, `Escalation Rate %`,
  `STR Conversion %`, `SLA Compliance %` as percentage.
- Sort "Cases by Status" by a status order column (New→Closed), not alphabetically.
- Keep one synced Date slicer across pages (Edit interactions / Sync slicers).
