# Screenshot Checklist

Export these into `screenshots/` for the GitHub README and LinkedIn portfolio.
Use a consistent window size and the same theme for all captures.

| # | File name | Page / content | Used in |
|---|---|---|---|
| 1 | `executive_overview.png` | Page 1 full view (KPI cards + GGR trend + funnel) | README hero image |
| 2 | `aml_monitoring.png` | Page 2 full view (alerts by rule + severity) | README, LinkedIn |
| 3 | `str_workflow.png` | Page 3 full view (status funnel + analyst workload + aging) | README, LinkedIn |
| 4 | `market_performance.png` | Page 4 full view (wagers vs GGR + product mix) | README, LinkedIn |
| 5 | `data_model.png` | Power BI Model view (relationship diagram) | README architecture |

## Capture tips
- Hide the filter/slicer pane edit handles before capturing.
- Make sure no visual shows an error or "(Blank)".
- Capture at ~1600px wide for crisp README rendering.
- For the model diagram, arrange tables so Date sits center with facts around it.

## After capturing
```
git add screenshots/*.png
git commit -m "Add Power BI dashboard screenshots"
git push
```
Then embed in README, e.g.:
```markdown
![Executive Overview](screenshots/executive_overview.png)
```
