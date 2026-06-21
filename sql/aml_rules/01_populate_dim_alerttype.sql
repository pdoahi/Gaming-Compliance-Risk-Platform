/* ============================================================================
   Phase 5 — Populate Dim_AlertType with the 10 AML rules
   Gaming Compliance & Risk Intelligence Platform
   Target: Microsoft SQL Server (T-SQL)

   Run after schema creation. Idempotent: clears and reloads the rule set.
   Base_Risk_Score drives severity per the framework scoring methodology.
   ============================================================================ */

DELETE FROM dbo.Dim_AlertType;
GO

SET IDENTITY_INSERT dbo.Dim_AlertType ON;
INSERT INTO dbo.Dim_AlertType
    (AlertType_Key, Rule_Code, Rule_Name, Typology, Default_Severity, Base_Risk_Score, [Description])
VALUES
 (1,'AML-R01','Large Transaction Detection','Placement','High',75,'Single transaction at/above CAD 10,000 reporting reference'),
 (2,'AML-R02','Structuring / Smurfing','Structuring','High',80,'>= 3 transactions in [9000,10000) by same account within 7 days'),
 (3,'AML-R03','Rapid Movement of Funds','Layering','High',78,'Inbound then >=90% outbound within 6 hours (same account)'),
 (4,'AML-R04','High Transaction Velocity','Layering','Medium',60,'>= 8 transactions by same account within 24 hours'),
 (5,'AML-R05','Sub-Threshold Multiple Transactions','Structuring','Medium',55,'>= 5 transactions < 10,000 by same account in one day'),
 (6,'AML-R06','High-Risk Payment Format','Placement','Medium',65,'Cash or Crypto transaction at/above 5,000'),
 (7,'AML-R07','Unusual Activity Spike','Behavioural','Medium',58,'Daily total >= 5x account median daily total and >= 5,000'),
 (8,'AML-R08','Dormant Account Reactivation','Account Misuse','Medium',62,'Gap >= 30 days then transaction >= 5,000'),
 (9,'AML-R09','Round-Number Large Transactions','Layering','Medium',50,'Amount >= 10,000 and an exact multiple of 1,000'),
 (10,'AML-R10','Counterparty Concentration','Layering','High',72,'>= 4 txns to same counterparty totaling >= 20,000 within 30 days'),
 (11,'AML-R11','Sanctions / Watchlist Match','Sanctions','Critical',95,'Transaction by an account matched to a sanctions/watchlist');
SET IDENTITY_INSERT dbo.Dim_AlertType OFF;
GO

PRINT 'Dim_AlertType populated with 10 AML rules.';
SELECT Rule_Code, Rule_Name, Default_Severity, Base_Risk_Score FROM dbo.Dim_AlertType ORDER BY AlertType_Key;
GO
