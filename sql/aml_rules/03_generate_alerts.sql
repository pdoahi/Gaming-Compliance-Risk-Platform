/* ============================================================================
   Phase 5 — Consolidated Alert Generation
   Gaming Compliance & Risk Intelligence Platform
   Target: Microsoft SQL Server (T-SQL)

   Unions all 10 rule views, joins rule metadata for scoring/severity, and
   inserts one alert row per (transaction x rule) match into Fact_AML_Alerts.

   Run after: 01_populate_dim_alerttype.sql, 02_aml_rule_views.sql
   ============================================================================ */

/* Status_Key for 'New' (initial alert state) */
DECLARE @StatusNew INT = (SELECT Status_Key FROM dbo.Dim_Status WHERE Status_Code = 'NEW');

/* Optional: clear prior generated alerts for a clean re-run */
DELETE FROM dbo.Fact_AML_Alerts WHERE SourceSystem = 'AML_Engine';

;WITH all_matches AS (
    SELECT * FROM dbo.vw_rule_R01_large_txn
    UNION ALL SELECT * FROM dbo.vw_rule_R02_structuring
    UNION ALL SELECT * FROM dbo.vw_rule_R03_rapid_movement
    UNION ALL SELECT * FROM dbo.vw_rule_R04_velocity
    UNION ALL SELECT * FROM dbo.vw_rule_R05_subthreshold
    UNION ALL SELECT * FROM dbo.vw_rule_R06_highrisk_format
    UNION ALL SELECT * FROM dbo.vw_rule_R07_spike
    UNION ALL SELECT * FROM dbo.vw_rule_R08_dormant
    UNION ALL SELECT * FROM dbo.vw_rule_R09_round_number
    UNION ALL SELECT * FROM dbo.vw_rule_R10_concentration
    UNION ALL SELECT * FROM dbo.vw_rule_R11_sanctions
)
INSERT INTO dbo.Fact_AML_Alerts
    (Transaction_Key, AlertType_Key, Account_Key, Player_Key, Date_Key,
     Status_Key, Risk_Score, Severity, Alert_Timestamp, Is_Escalated, SourceSystem)
SELECT
    m.Transaction_Key,
    m.AlertType_Key,
    t.Account_Key,
    t.Player_Key,
    t.Date_Key,
    @StatusNew,
    at.Base_Risk_Score,
    CASE                                            -- severity from score bands
        WHEN at.Base_Risk_Score >= 90 THEN 'Critical'
        WHEN at.Base_Risk_Score >= 70 THEN 'High'
        WHEN at.Base_Risk_Score >= 40 THEN 'Medium'
        ELSE 'Low'
    END,
    t.Transaction_Timestamp,
    CASE WHEN at.Base_Risk_Score >= 70 THEN 1 ELSE 0 END,   -- auto-escalate >= 70
    'AML_Engine'
FROM all_matches m
JOIN dbo.Fact_Transactions t ON t.Transaction_Key = m.Transaction_Key
JOIN dbo.Dim_AlertType at     ON at.AlertType_Key  = m.AlertType_Key;

PRINT CONCAT('Alerts generated: ', @@ROWCOUNT);
GO

/* Summary by rule */
SELECT at.Rule_Code, at.Rule_Name, COUNT(*) AS Alerts,
       SUM(CAST(a.Is_Escalated AS INT)) AS Escalated
FROM dbo.Fact_AML_Alerts a
JOIN dbo.Dim_AlertType at ON at.AlertType_Key = a.AlertType_Key
WHERE a.SourceSystem = 'AML_Engine'
GROUP BY at.Rule_Code, at.Rule_Name
ORDER BY at.Rule_Code;
GO
