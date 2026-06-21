# Final Report — Methodology & Results
## Gaming Compliance & Risk Intelligence Platform

A companion to the [README](../README.md), documenting methodology, detailed results,
and recommendations to a professional standard.

---

## 1. Methodology by Phase

| Phase | Approach | Output |
|---|---|---|
| 1 Architecture | Consulting-style blueprint: business case, regulatory context, stakeholders, risks | `architecture_blueprint.md` |
| 2 Data Model | Star schema, conformed dimensions, explicit grain, source tagging | `data_model.md` |
| 3 SQL Foundation | 3-layer warehouse (staging→analytics→reporting); constraints, DQ, views; verified via SQLite build | `sql/` |
| 4 Exploration | Profiling, cleaning, derived features; reproducible synthetic generator | `notebooks/01` |
| 5 AML Rules | 11 typologies (incl. sanctions screening) + customer risk rating; SQL + pandas; validated vs ground truth | `aml_monitoring_framework.md`, `sql/aml_rules`, `notebooks/02` |
| 5b ML Baseline | Logistic-regression model vs rules on a held-out test set | `notebooks/05` |
| 6 STR Workflow | Lifecycle, SLAs, audit trail; case simulation + KPIs | `str_workflow.md`, `sql/str_workflow`, `notebooks/03` |
| 7 GGR Reporting | Synthetic market series analyzed and reported | `notebooks/04` |
| 8 Dashboards | 4-page spec + DAX/Power Query/model package | `dashboard_specification.md`, `powerbi/` |
| 9 Documentation | Portfolio README + this report | `README.md`, this file |

---

## 2. AML Validation — Detailed Results

Validated against the `Is_Laundering` ground-truth label on ~5,400 transactions.

**Overall:** Recall 99.4% · Precision 86.9% · F1 0.927
**Confusion matrix:** TP 486 · FP 73 · FN 3 · TN 4,839

> **Validation caveat (important).** The data is synthetic and the laundering typologies
> were injected to match the rules, so these figures are **optimistic** — they confirm
> the rules detect their intended patterns, not expected production performance. On real,
> unlabelled data both metrics would be lower and need recalibration.

### Interpretation
- **High recall** means few laundering transactions slip through — the priority in AML,
  where a missed STR is a regulatory failure.
- **Precision (87%)** reflects the analyst-workload cost (73 false positives) that
  threshold tuning would balance.
- The handful of **false negatives** sit in low-signal typologies — candidates for ML
  augmentation (see §2b).

### 2b. ML baseline comparison
A logistic-regression model on **behavioural features only** (sanctions/PEP excluded to
avoid label leakage) achieved **ROC-AUC ≈ 0.98** on a held-out test set (F1 ≈ 0.70 at a
0.5 threshold). The rules outperform on these injected typologies, but the model adds a
**continuous risk probability** for ranking alerts — hence the recommended hybrid:
explainable rules as the backbone, ML for prioritization and novel-pattern discovery.

### Per-rule behaviour
High-precision rules (large transaction, structuring, rapid movement, round-number,
counterparty concentration) drive most true positives. Broader behavioural rules
(activity spike, high-risk format) add recall at some precision cost — the expected
trade-off a compliance team tunes via thresholds.

---

## 3. STR Workflow — Detailed Results

From the escalated alerts, **362 distinct-transaction cases** were created and run
through a simulated lifecycle:

- **Backlog:** 184 open cases across New / Under Review / Escalated / STR Submitted.
- **STR conversion:** 57.2% overall — high because cases are the already-escalated,
  high-precision subset; true-laundering cases convert far more than false positives.
- **SLA compliance:** 93.8% of closed cases met their priority-based SLA.
- **Throughput:** 5.0-day average investigation time on closed cases.

These are the metrics a compliance lead reviews weekly to manage workload and
regulatory timeliness.

---

## 4. Market (GGR) — Detailed Results

Synthetic monthly market series (48 months), analyzed and aggregated to fiscal-year totals.

- **Growth:** monthly GGR rose ~3x (≈$27M → ≈$76M); FY25 reached ≈$20.5B wagered /
  ≈$0.82B GGR (+53% YoY) — illustrative, generated figures only.
- **Margin:** hold stable at ~3.9–4.1% — consistent revenue quality as volume scales.
- **Mix:** Casino ~66% of GGR, Sports second, Poker a small steady share; sports
  seasonality visible in betting.

---

## 5. Recommendations

1. **Augment rules with ML** for the low-signal typologies driving false negatives.
2. **Tune high-volume / lower-precision rules** (activity spike, high-risk format) to
   cut analyst workload without material recall loss.
3. **Add network analytics** to strengthen counterparty-concentration and circular-flow
   detection.
4. **Operationalize** with orchestration, a live warehouse, and automated STR filing.
5. **Introduce SCD Type 2** to track player-risk and KYC changes over time.

---

## 6. Assurance & Transparency

- All data — AML, STR, and the market/GGR series — is synthetic and clearly labelled;
  the figures are illustrative and represent no real market.
- All notebooks are executed with outputs committed; SQL logic verified via SQLite and
  the Python implementations.
- The pipeline is reproducible from `requirements.txt` and the in-repo generator.
