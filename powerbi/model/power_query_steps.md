# Power Query (M) — Load & Transform Steps

Paste each query into Power BI (Home → Transform data → New Source → Blank Query →
Advanced Editor). Adjust the folder path in the `Source` line to your local repo.

> Set a parameter `RepoPath` (Manage Parameters) to your repo root, e.g.
> `C:\Users\you\Gaming-Compliance-Risk-Platform`, and reference it below.

## Transactions
```m
let
    Source = Csv.Document(File.Contents(RepoPath & "\data_processed\transactions_clean.csv"),
                          [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    Typed = Table.TransformColumnTypes(Promoted, {
        {"Timestamp", type datetime}, {"Amount_Paid", type number},
        {"Is_Laundering", Int64.Type}, {"Transaction_Hour", Int64.Type}}),
    WithID = Table.AddIndexColumn(Typed, "Transaction_ID", 0, 1, Int64.Type),
    WithDate = Table.AddColumn(WithID, "Timestamp_Date", each Date.From([Timestamp]), type date)
in
    WithDate
```

## AML_Alerts
```m
let
    Source = Csv.Document(File.Contents(RepoPath & "\data_processed\aml_alerts.csv"),
                          [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    Typed = Table.TransformColumnTypes(Promoted, {
        {"Transaction_ID", Int64.Type}, {"Risk_Score", Int64.Type},
        {"Is_Escalated", Int64.Type}, {"Is_Laundering", Int64.Type},
        {"Amount_Paid", type number}, {"Timestamp", type datetime}}),
    WithDate = Table.AddColumn(Typed, "Timestamp_Date", each Date.From([Timestamp]), type date)
in
    WithDate
```

## STR_Cases
```m
let
    Source = Csv.Document(File.Contents(RepoPath & "\data_processed\str_cases.csv"),
                          [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    Typed = Table.TransformColumnTypes(Promoted, {
        {"Case_Key", Int64.Type}, {"Transaction_ID", Int64.Type},
        {"STR_Submitted_Flag", Int64.Type}, {"SLA_Days", Int64.Type},
        {"Investigation_Days", Int64.Type}, {"SLA_Breached", Int64.Type},
        {"Open_Date", type date}, {"Close_Date", type date}})
in
    Typed
```

## Market
```m
let
    Source = Csv.Document(File.Contents(RepoPath & "\data_processed\market_performance_clean.csv"),
                          [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    Typed = Table.TransformColumnTypes(Promoted, {
        {"Date", type date}, {"CashWagers_M", type number}, {"NAGGR_M", type number},
        {"Hold_Pct", type number}, {"Active_Accounts", Int64.Type},
        {"ARPPA", type number}, {"GGR_YoY_Pct", type number}})
in
    Typed
```

## Market_Product
```m
let
    Source = Csv.Document(File.Contents(RepoPath & "\data_raw\market_by_product_synthetic.csv"),
                          [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    Typed = Table.TransformColumnTypes(Promoted, {
        {"CashWagers_M", type number}, {"NAGGR_M", type number},
        {"WagerShare", type number}, {"GGRShare", type number}}),
    WithDate = Table.AddColumn(Typed, "Date", each Date.FromText([YearMonth] & "-01"), type date)
in
    WithDate
```
