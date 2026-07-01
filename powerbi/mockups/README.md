# Dashboard Mockups (design concepts)

> ⚠️ **These are illustrative DESIGN MOCKUPS — not screenshots of a live dashboard.**
> They visualize the layout and visuals described in
> [`../../documentation/dashboard_specification.md`](../../documentation/dashboard_specification.md)
> so the intended design is easy to see before the Power BI `.pbix` is built. Every number
> shown is illustrative. The actual, interactive Power BI file is assembled in Power BI
> Desktop from the [`/powerbi`](..) package.

## The four pages

| Page | Mockup | Design spec |
|---|---|---|
| 1 — Executive Overview | [`1_executive_overview.png`](1_executive_overview.png) | market scale + program health for leadership |
| 2 — AML Monitoring | [`2_aml_monitoring.png`](2_aml_monitoring.png) | alerts by rule/severity, risk distribution, top accounts |
| 3 — STR Workflow | [`3_str_workflow.png`](3_str_workflow.png) | case pipeline, analyst workload, aging, SLA compliance |
| 4 — Market Performance | [`4_market_performance.png`](4_market_performance.png) | wagers/GGR trends, product mix, fiscal-year GGR |

Each page carries a **"DESIGN MOCKUP · illustrative"** badge in its header, and a footer
noting it is not a live dashboard.

## Files
- `*.png` — the mockup images (1600 × 1600).
- `*.svg` — the editable vector source for each mockup.

## Theme
Matches the spec: severity colors (Low `#16a34a`, Medium `#ca8a04`, High `#ea580c`,
Critical `#dc2626`), primary `#2563eb`, neutral grays.
