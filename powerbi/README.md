# Power BI — Dashboard Layer (Phase 8)

Everything needed to assemble the `.pbix` is pre-written here. The final
clicking-together and screenshots are done in Power BI Desktop (GUI).

## Contents

```
powerbi/
├── dax/                    DAX: date table + market / AML / STR measures
│   ├── 00_date_table.dax
│   ├── 01_market_measures.dax
│   ├── 02_aml_measures.dax
│   └── 03_str_measures.dax
├── model/
│   ├── data_model.md       Tables, relationships, naming conventions
│   └── power_query_steps.md  M queries to load each CSV
├── documentation/
│   ├── build_guide.md      Step-by-step assembly
│   └── screenshot_checklist.md
└── pbix/                   Place the built Gaming_Compliance.pbix here
```

## Start here
1. [`documentation/build_guide.md`](documentation/build_guide.md) — the assembly steps
2. Dashboard design: [`../documentation/dashboard_specification.md`](../documentation/dashboard_specification.md)

## Data sources
Four pages are driven by `data_processed/` (transactions, AML alerts, STR cases,
monthly market) plus `data_raw/market_by_product_synthetic.csv`, joined through a
generated Date table. All measures are validated against the actual column names
in those files.
