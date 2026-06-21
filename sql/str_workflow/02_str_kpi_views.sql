/* ============================================================================
   Phase 6 — STR Workflow KPI Views
   Gaming Compliance & Risk Intelligence Platform
   Target: Microsoft SQL Server (T-SQL)

   Reporting views over Fact_STR_Cases for the STR dashboard (Phase 8).
   Run after STR cases are loaded.
   ============================================================================ */

/* ---- Cases by status (pipeline / funnel) ---- */
IF OBJECT_ID('dbo.vw_str_cases_by_status','V') IS NOT NULL DROP VIEW dbo.vw_str_cases_by_status;
GO
CREATE VIEW dbo.vw_str_cases_by_status AS
SELECT s.Workflow_Order, s.Status_Name, s.Status_Category,
       COUNT(*) AS Case_Count
FROM dbo.Fact_STR_Cases c
JOIN dbo.Dim_Status s ON s.Status_Key = c.Status_Key
GROUP BY s.Workflow_Order, s.Status_Name, s.Status_Category;
GO

/* ---- Cases by analyst (workload) ---- */
IF OBJECT_ID('dbo.vw_str_cases_by_analyst','V') IS NOT NULL DROP VIEW dbo.vw_str_cases_by_analyst;
GO
CREATE VIEW dbo.vw_str_cases_by_analyst AS
SELECT a.Analyst_ID, a.Analyst_Name, a.Team,
       COUNT(*)                                   AS Total_Cases,
       SUM(CASE WHEN s.Is_Terminal = 0 THEN 1 ELSE 0 END) AS Open_Cases,
       SUM(c.STR_Submitted_Flag)                  AS STRs_Filed,
       SUM(c.SLA_Breached)                         AS SLA_Breaches,
       AVG(CAST(c.Investigation_Days AS FLOAT))    AS Avg_Investigation_Days
FROM dbo.Fact_STR_Cases c
JOIN dbo.Dim_Analyst a ON a.Analyst_Key = c.Analyst_Key
JOIN dbo.Dim_Status  s ON s.Status_Key  = c.Status_Key
GROUP BY a.Analyst_ID, a.Analyst_Name, a.Team;
GO

/* ---- Program KPI summary (single row) ---- */
IF OBJECT_ID('dbo.vw_str_kpi_summary','V') IS NOT NULL DROP VIEW dbo.vw_str_kpi_summary;
GO
CREATE VIEW dbo.vw_str_kpi_summary AS
SELECT
    COUNT(*)                                                       AS Total_Cases,
    SUM(CASE WHEN s.Is_Terminal = 0 THEN 1 ELSE 0 END)            AS Backlog_Open_Cases,
    SUM(c.STR_Submitted_Flag)                                     AS STRs_Filed,
    CAST(100.0 * SUM(c.STR_Submitted_Flag) / NULLIF(COUNT(*),0) AS DECIMAL(5,1)) AS STR_Conversion_Rate_Pct,
    AVG(CASE WHEN s.Is_Terminal = 1 THEN CAST(c.Investigation_Days AS FLOAT) END) AS Avg_Investigation_Days_Closed,
    CAST(100.0 * SUM(CASE WHEN s.Is_Terminal = 1 AND c.SLA_Breached = 0 THEN 1 ELSE 0 END)
         / NULLIF(SUM(CASE WHEN s.Is_Terminal = 1 THEN 1 ELSE 0 END),0) AS DECIMAL(5,1)) AS SLA_Compliance_Rate_Pct
FROM dbo.Fact_STR_Cases c
JOIN dbo.Dim_Status s ON s.Status_Key = c.Status_Key;
GO

/* ---- Aging open cases (buckets by days open) ---- */
IF OBJECT_ID('dbo.vw_str_aging','V') IS NOT NULL DROP VIEW dbo.vw_str_aging;
GO
CREATE VIEW dbo.vw_str_aging AS
SELECT
    CASE
        WHEN c.Investigation_Days <= 7  THEN '0-7 days'
        WHEN c.Investigation_Days <= 14 THEN '8-14 days'
        WHEN c.Investigation_Days <= 30 THEN '15-30 days'
        ELSE '30+ days'
    END AS Age_Bucket,
    COUNT(*) AS Open_Cases
FROM dbo.Fact_STR_Cases c
JOIN dbo.Dim_Status s ON s.Status_Key = c.Status_Key
WHERE s.Is_Terminal = 0
GROUP BY CASE
        WHEN c.Investigation_Days <= 7  THEN '0-7 days'
        WHEN c.Investigation_Days <= 14 THEN '8-14 days'
        WHEN c.Investigation_Days <= 30 THEN '15-30 days'
        ELSE '30+ days'
    END;
GO

PRINT 'STR KPI views created.';
GO
