/* ============================================================================
   Phase 3 — Test Data
   Gaming Compliance & Risk Intelligence Platform
   Target: Microsoft SQL Server (T-SQL)

   Minimal sample data to validate schema, constraints, views, and DQ checks
   BEFORE loading the full synthetic datasets. All player/analyst/case data is
   SYNTHETIC and clearly labelled. Run AFTER schema creation.
   ============================================================================ */

SET NOCOUNT ON;

/* ---- Dim_Date: a few days spanning two months ---- */
INSERT INTO dbo.Dim_Date (Date_Key, Full_Date, [Day], [Month], Month_Name, [Quarter], [Year], Year_Month, Day_Of_Week, Is_Weekend, Fiscal_Year)
VALUES
 (20240401,'2024-04-01',1,4,'April',2,2024,'2024-04','Monday',0,2024),
 (20240412,'2024-04-12',12,4,'April',2,2024,'2024-04','Friday',0,2024),
 (20240501,'2024-05-01',1,5,'May',2,2024,'2024-05','Wednesday',0,2024),
 (20240515,'2024-05-15',15,5,'May',2,2024,'2024-05','Wednesday',0,2024);

/* ---- Dim_Player (SYNTHETIC) ---- */
INSERT INTO dbo.Dim_Player (Player_ID, Registration_Date, Province, KYC_Status, KYC_Risk_Level, PEP_Flag, Self_Exclusion_Flag, SourceSystem)
VALUES
 ('PLR-00552','2023-02-10','Region-A','Verified','Medium',0,0,'Synthetic'),
 ('PLR-00553','2023-06-01','Region-A','Verified','High',0,0,'Synthetic'),
 ('PLR-00554','2024-01-15','Region-B','Pending','Low',0,0,'Synthetic');

/* ---- Dim_Account ---- */
INSERT INTO dbo.Dim_Account (Account_ID, Player_Key, Account_Type, Account_Open_Date, Account_Status, Home_Bank, Risk_Rating, SourceSystem)
VALUES
 ('ACC-80021',1,'Player Wallet','2023-02-14','Active','Bank_07','Medium','IBM_AML'),
 ('ACC-80022',2,'Player Wallet','2023-06-05','Active','Bank_03','High','IBM_AML'),
 ('ACC-90100',NULL,'External','2023-01-01','Active','Bank_11','Low','IBM_AML');

/* ---- Dim_AlertType (sample; full set in Phase 5) ---- */
INSERT INTO dbo.Dim_AlertType (Rule_Code, Rule_Name, Typology, Default_Severity, Base_Risk_Score, [Description])
VALUES
 ('AML-R01','Large Transaction Detection','Placement','High',75,'Single transaction over reporting threshold'),
 ('AML-R03','Rapid Movement of Funds','Layering','High',70,'Funds deposited and withdrawn within a short window');

/* ---- Dim_Status (full workflow) ---- */
INSERT INTO dbo.Dim_Status (Status_Code, Status_Name, Status_Category, Workflow_Order, Is_Terminal)
VALUES
 ('NEW','New','Open',1,0),
 ('REVIEW','Under Review','Open',2,0),
 ('ESC','Escalated','Open',3,0),
 ('STR_SUB','STR Submitted','Open',4,0),
 ('CLOSED','Closed','Closed',5,1);

/* ---- Dim_Analyst (SYNTHETIC names) ---- */
INSERT INTO dbo.Dim_Analyst (Analyst_ID, Analyst_Name, Team, Seniority, Active_Flag, SourceSystem)
VALUES
 ('AN-007','Jordan Vale (synthetic)','Investigations','Senior',1,'Synthetic'),
 ('AN-011','Priya Anand (synthetic)','AML Ops','Junior',1,'Synthetic');

/* ---- Fact_Transactions ---- */
INSERT INTO dbo.Fact_Transactions (Date_Key, Account_Key, Counterparty_Account_Key, Player_Key, Transaction_Timestamp, Amount, Currency, Payment_Format, Transaction_Direction, Is_Laundering, SourceSystem)
VALUES
 (20240401,1,3,1,'2024-04-01T14:22:00',8500.00,'CAD','Wire','Deposit',1,'IBM_AML'),
 (20240401,2,3,2,'2024-04-01T09:10:00',1200.00,'CAD','Credit Card','Deposit',0,'IBM_AML'),
 (20240412,1,3,1,'2024-04-12T18:05:00',8200.00,'CAD','Wire','Withdrawal',1,'IBM_AML');

/* ---- Fact_AML_Alerts (Status 3 = Escalated, 2 = Under Review per insert order) ---- */
INSERT INTO dbo.Fact_AML_Alerts (Transaction_Key, AlertType_Key, Account_Key, Player_Key, Date_Key, Status_Key, Risk_Score, Severity, Alert_Timestamp, Is_Escalated, SourceSystem)
VALUES
 (1,1,1,1,20240401,3,78,'High','2024-04-01T14:25:00',1,'AML_Engine'),
 (3,2,1,1,20240412,2,70,'High','2024-04-12T18:10:00',0,'AML_Engine');

/* ---- Fact_STR_Cases (SYNTHETIC) ---- */
INSERT INTO dbo.Fact_STR_Cases (Alert_Key, Analyst_Key, Player_Key, Status_Key, Open_Date_Key, Close_Date_Key, Case_Priority, SLA_Days, Investigation_Days, SLA_Breached, STR_Submitted_Flag, Closure_Reason)
VALUES
 (1,1,1,5,20240401,20240412,'High',10,11,1,1,'STR Filed with FINTRAC (synthetic)');

/* ---- Fact_MarketPerformance (illustrative figures) ---- */
INSERT INTO dbo.Fact_MarketPerformance (Date_Key, Reporting_Period, Total_Wagers, Total_GGR, Active_Player_Accounts, GGR_Per_Active_Account, Hold_Percentage, MoM_GGR_Growth)
VALUES
 (20240401,'2024-04',17800000000.00,658000000.00,1100000,598.18,3.70,2.10),
 (20240501,'2024-05',18200000000.00,672000000.00,1125000,597.33,3.69,2.13);

PRINT 'Test data inserted.';
GO

/* ---- Quick validation roll-up ---- */
SELECT 'Dim_Date' AS TableName, COUNT(*) AS Rows FROM dbo.Dim_Date
UNION ALL SELECT 'Dim_Player', COUNT(*) FROM dbo.Dim_Player
UNION ALL SELECT 'Dim_Account', COUNT(*) FROM dbo.Dim_Account
UNION ALL SELECT 'Dim_AlertType', COUNT(*) FROM dbo.Dim_AlertType
UNION ALL SELECT 'Dim_Status', COUNT(*) FROM dbo.Dim_Status
UNION ALL SELECT 'Dim_Analyst', COUNT(*) FROM dbo.Dim_Analyst
UNION ALL SELECT 'Fact_Transactions', COUNT(*) FROM dbo.Fact_Transactions
UNION ALL SELECT 'Fact_AML_Alerts', COUNT(*) FROM dbo.Fact_AML_Alerts
UNION ALL SELECT 'Fact_STR_Cases', COUNT(*) FROM dbo.Fact_STR_Cases
UNION ALL SELECT 'Fact_MarketPerformance', COUNT(*) FROM dbo.Fact_MarketPerformance;
GO
