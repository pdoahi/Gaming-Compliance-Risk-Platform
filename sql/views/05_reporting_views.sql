/* ============================================================================
   Phase 3 — Analytical Reporting Views
   Gaming Compliance & Risk Intelligence Platform
   Target: Microsoft SQL Server (T-SQL)

   The reporting layer Power BI and notebooks consume. Business-friendly names,
   pre-joined and pre-aggregated. Run AFTER schema + data load.
   ============================================================================ */

/* ----------------------------------------------------------------------------
   vw_TransactionSummary
   Purpose: monthly transaction volume/value by direction. Feeds trend charts.
   Use cases: transaction trend analysis, deposit/withdrawal mix.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.vw_TransactionSummary', 'V') IS NOT NULL DROP VIEW dbo.vw_TransactionSummary;
GO
CREATE VIEW dbo.vw_TransactionSummary AS
SELECT
    d.Year_Month,
    f.Transaction_Direction,
    COUNT(*)              AS Transaction_Count,
    SUM(f.Amount)         AS Total_Amount,
    AVG(f.Amount)         AS Avg_Amount,
    SUM(CAST(f.Is_Laundering AS INT)) AS Flagged_Laundering_Count
FROM dbo.Fact_Transactions f
JOIN dbo.Dim_Date d ON d.Date_Key = f.Date_Key
GROUP BY d.Year_Month, f.Transaction_Direction;
GO

/* ----------------------------------------------------------------------------
   vw_AlertSummary
   Purpose: alert counts by rule, severity, and month. Core AML dashboard feed.
   Use cases: alerts by rule, alerts by severity, escalation rate.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.vw_AlertSummary', 'V') IS NOT NULL DROP VIEW dbo.vw_AlertSummary;
GO
CREATE VIEW dbo.vw_AlertSummary AS
SELECT
    d.Year_Month,
    at.Rule_Code,
    at.Rule_Name,
    at.Typology,
    a.Severity,
    COUNT(*)                                   AS Alert_Count,
    SUM(CAST(a.Is_Escalated AS INT))           AS Escalated_Count,
    AVG(a.Risk_Score)                          AS Avg_Risk_Score
FROM dbo.Fact_AML_Alerts a
JOIN dbo.Dim_Date d       ON d.Date_Key      = a.Date_Key
JOIN dbo.Dim_AlertType at ON at.AlertType_Key = a.AlertType_Key
GROUP BY d.Year_Month, at.Rule_Code, at.Rule_Name, at.Typology, a.Severity;
GO

/* ----------------------------------------------------------------------------
   vw_STRSummary
   Purpose: STR case workflow metrics by status and analyst. Feeds STR dashboard.
   Use cases: cases by status, SLA breaches, analyst workload, avg investigation.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.vw_STRSummary', 'V') IS NOT NULL DROP VIEW dbo.vw_STRSummary;
GO
CREATE VIEW dbo.vw_STRSummary AS
SELECT
    s.Status_Name,
    s.Status_Category,
    an.Analyst_Name,
    an.Team,
    COUNT(*)                                  AS Case_Count,
    SUM(c.STR_Submitted_Flag)                 AS STR_Submitted_Count,
    SUM(c.SLA_Breached)                        AS SLA_Breached_Count,
    AVG(CAST(c.Investigation_Days AS FLOAT))   AS Avg_Investigation_Days
FROM dbo.Fact_STR_Cases c
JOIN dbo.Dim_Status s   ON s.Status_Key  = c.Status_Key
LEFT JOIN dbo.Dim_Analyst an ON an.Analyst_Key = c.Analyst_Key
GROUP BY s.Status_Name, s.Status_Category, an.Analyst_Name, an.Team;
GO

/* ----------------------------------------------------------------------------
   vw_MarketPerformanceSummary
   Purpose: monthly GGR market metrics with growth. Feeds market dashboard.
   Use cases: GGR trend, wagers, active accounts, hold %, MoM growth.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.vw_MarketPerformanceSummary', 'V') IS NOT NULL DROP VIEW dbo.vw_MarketPerformanceSummary;
GO
CREATE VIEW dbo.vw_MarketPerformanceSummary AS
SELECT
    m.Reporting_Period,
    d.[Year],
    d.Month_Name,
    m.Total_Wagers,
    m.Total_GGR,
    m.Active_Player_Accounts,
    m.GGR_Per_Active_Account,
    m.Hold_Percentage,
    LAG(m.Total_GGR) OVER (ORDER BY m.Reporting_Period) AS Prev_Month_GGR,
    CASE WHEN LAG(m.Total_GGR) OVER (ORDER BY m.Reporting_Period) > 0
         THEN 100.0 * (m.Total_GGR - LAG(m.Total_GGR) OVER (ORDER BY m.Reporting_Period))
              / LAG(m.Total_GGR) OVER (ORDER BY m.Reporting_Period)
         END AS MoM_GGR_Growth_Pct
FROM dbo.Fact_MarketPerformance m
JOIN dbo.Dim_Date d ON d.Date_Key = m.Date_Key;
GO

/* ----------------------------------------------------------------------------
   vw_ExecutiveComplianceMetrics
   Purpose: single-row-per-month executive KPI roll-up combining market + AML +
   STR. Feeds the Executive Overview dashboard.
   Use cases: CCO/board reporting, program health at a glance.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.vw_ExecutiveComplianceMetrics', 'V') IS NOT NULL DROP VIEW dbo.vw_ExecutiveComplianceMetrics;
GO
CREATE VIEW dbo.vw_ExecutiveComplianceMetrics AS
WITH alerts AS (
    SELECT d.Year_Month,
           COUNT(*) AS Alert_Count,
           SUM(CAST(a.Is_Escalated AS INT)) AS Escalated_Count
    FROM dbo.Fact_AML_Alerts a
    JOIN dbo.Dim_Date d ON d.Date_Key = a.Date_Key
    GROUP BY d.Year_Month
),
cases AS (
    SELECT d.Year_Month,
           COUNT(*) AS Case_Count,
           SUM(c.STR_Submitted_Flag) AS STR_Count,
           SUM(c.SLA_Breached) AS SLA_Breaches
    FROM dbo.Fact_STR_Cases c
    JOIN dbo.Dim_Date d ON d.Date_Key = c.Open_Date_Key
    GROUP BY d.Year_Month
)
SELECT
    m.Reporting_Period                         AS Year_Month,
    m.Total_Wagers,
    m.Total_GGR,
    m.Active_Player_Accounts,
    COALESCE(al.Alert_Count, 0)                AS AML_Alerts,
    COALESCE(al.Escalated_Count, 0)            AS Escalated_Alerts,
    COALESCE(c.Case_Count, 0)                  AS STR_Cases,
    COALESCE(c.STR_Count, 0)                   AS STRs_Submitted,
    COALESCE(c.SLA_Breaches, 0)                AS SLA_Breaches,
    CASE WHEN al.Alert_Count > 0
         THEN 100.0 * al.Escalated_Count / al.Alert_Count END AS Escalation_Rate_Pct
FROM dbo.Fact_MarketPerformance m
LEFT JOIN alerts al ON al.Year_Month = m.Reporting_Period
LEFT JOIN cases  c  ON c.Year_Month  = m.Reporting_Period;
GO

PRINT 'Reporting views created: vw_TransactionSummary, vw_AlertSummary, vw_STRSummary, vw_MarketPerformanceSummary, vw_ExecutiveComplianceMetrics';
GO
