/* ============================================================================
   Phase 5 — AML Rule Validation Queries
   Gaming Compliance & Risk Intelligence Platform
   Target: Microsoft SQL Server (T-SQL)

   Validates generated alerts against the Is_Laundering ground-truth label.
   Reports recall, precision, confusion matrix, and per-rule precision.
   Run after: 03_generate_alerts.sql
   ============================================================================ */

/* ---- Flagged set: distinct transactions with >= 1 alert ---- */
;WITH flagged AS (
    SELECT DISTINCT Transaction_Key FROM dbo.Fact_AML_Alerts WHERE SourceSystem = 'AML_Engine'
),
labelled AS (
    SELECT t.Transaction_Key, t.Is_Laundering,
           CASE WHEN f.Transaction_Key IS NOT NULL THEN 1 ELSE 0 END AS Flagged
    FROM dbo.Fact_Transactions t
    LEFT JOIN flagged f ON f.Transaction_Key = t.Transaction_Key
)
SELECT
    SUM(CASE WHEN Is_Laundering = 1 AND Flagged = 1 THEN 1 ELSE 0 END) AS True_Positives,
    SUM(CASE WHEN Is_Laundering = 0 AND Flagged = 1 THEN 1 ELSE 0 END) AS False_Positives,
    SUM(CASE WHEN Is_Laundering = 1 AND Flagged = 0 THEN 1 ELSE 0 END) AS False_Negatives,
    SUM(CASE WHEN Is_Laundering = 0 AND Flagged = 0 THEN 1 ELSE 0 END) AS True_Negatives,
    CAST(100.0 * SUM(CASE WHEN Is_Laundering = 1 AND Flagged = 1 THEN 1 ELSE 0 END)
         / NULLIF(SUM(CASE WHEN Is_Laundering = 1 THEN 1 ELSE 0 END),0) AS DECIMAL(5,1)) AS Recall_Pct,
    CAST(100.0 * SUM(CASE WHEN Is_Laundering = 1 AND Flagged = 1 THEN 1 ELSE 0 END)
         / NULLIF(SUM(CASE WHEN Flagged = 1 THEN 1 ELSE 0 END),0) AS DECIMAL(5,1)) AS Precision_Pct
FROM labelled;
GO

/* ---- Per-rule precision (how clean is each rule's output) ---- */
SELECT at.Rule_Code, at.Rule_Name,
       COUNT(*) AS Alerts,
       SUM(CAST(t.Is_Laundering AS INT)) AS True_Laundering,
       CAST(100.0 * SUM(CAST(t.Is_Laundering AS INT)) / COUNT(*) AS DECIMAL(5,1)) AS Precision_Pct
FROM dbo.Fact_AML_Alerts a
JOIN dbo.Dim_AlertType at     ON at.AlertType_Key  = a.AlertType_Key
JOIN dbo.Fact_Transactions t  ON t.Transaction_Key = a.Transaction_Key
WHERE a.SourceSystem = 'AML_Engine'
GROUP BY at.Rule_Code, at.Rule_Name
ORDER BY at.Rule_Code;
GO
