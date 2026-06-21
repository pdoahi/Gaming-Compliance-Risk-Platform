/* ============================================================================
   Phase 3 — Data Quality Framework
   Gaming Compliance & Risk Intelligence Platform
   Target: Microsoft SQL Server (T-SQL)

   Validation checks run AFTER data load. Each check returns the offending rows
   (or a count). In production these would write to a DQ results/log table and
   fail the batch on critical violations. Run any time after load.
   ============================================================================ */

PRINT '================ TRANSACTION DATA QUALITY ================';

/* DQ-T01: NULLs in required fields */
SELECT 'DQ-T01 Null required fields' AS Check_Name, COUNT(*) AS Failing_Rows
FROM   dbo.Fact_Transactions
WHERE  Date_Key IS NULL OR Account_Key IS NULL OR Amount IS NULL
   OR  Transaction_Timestamp IS NULL;

/* DQ-T02: Duplicate transactions (same account, timestamp, amount, counterparty) */
SELECT 'DQ-T02 Duplicate transactions' AS Check_Name, COUNT(*) AS Failing_Rows
FROM (
    SELECT Account_Key, Transaction_Timestamp, Amount, Counterparty_Account_Key, COUNT(*) AS c
    FROM   dbo.Fact_Transactions
    GROUP BY Account_Key, Transaction_Timestamp, Amount, Counterparty_Account_Key
    HAVING COUNT(*) > 1
) d;

/* DQ-T03: Invalid timestamps (future-dated or before market launch 2022-04-04) */
SELECT 'DQ-T03 Invalid timestamps' AS Check_Name, COUNT(*) AS Failing_Rows
FROM   dbo.Fact_Transactions
WHERE  Transaction_Timestamp > GETDATE()
   OR  Transaction_Timestamp < '2022-04-04';

/* DQ-T04: Orphaned account keys (FK integrity backstop) */
SELECT 'DQ-T04 Invalid account IDs' AS Check_Name, COUNT(*) AS Failing_Rows
FROM   dbo.Fact_Transactions f
LEFT JOIN dbo.Dim_Account a ON a.Account_Key = f.Account_Key
WHERE  a.Account_Key IS NULL;

/* DQ-T05: Negative transaction amounts */
SELECT 'DQ-T05 Negative amounts' AS Check_Name, COUNT(*) AS Failing_Rows
FROM   dbo.Fact_Transactions
WHERE  Amount < 0;

PRINT '================ MARKET DATA QUALITY ================';

/* DQ-M01: Missing reporting periods (gap detection in monthly sequence) */
;WITH ordered AS (
    SELECT Reporting_Period,
           LAG(Reporting_Period) OVER (ORDER BY Reporting_Period) AS Prev_Period
    FROM dbo.Fact_MarketPerformance
)
SELECT 'DQ-M01 Missing periods (gaps)' AS Check_Name, COUNT(*) AS Failing_Rows
FROM ordered
WHERE Prev_Period IS NOT NULL
  AND DATEDIFF(MONTH,
        CONVERT(DATE, Prev_Period + '-01'),
        CONVERT(DATE, Reporting_Period + '-01')) <> 1;

/* DQ-M02: Invalid revenue values (GGR > Wagers is impossible) */
SELECT 'DQ-M02 GGR exceeds wagers' AS Check_Name, COUNT(*) AS Failing_Rows
FROM   dbo.Fact_MarketPerformance
WHERE  Total_GGR > Total_Wagers
   OR  Total_GGR < 0 OR Total_Wagers < 0;

/* DQ-M03: Invalid active account counts */
SELECT 'DQ-M03 Invalid active accounts' AS Check_Name, COUNT(*) AS Failing_Rows
FROM   dbo.Fact_MarketPerformance
WHERE  Active_Player_Accounts <= 0;

PRINT '================ CROSS-TABLE INTEGRITY ================';

/* DQ-X01: Alerts referencing a transaction that does not exist */
SELECT 'DQ-X01 Orphan alerts' AS Check_Name, COUNT(*) AS Failing_Rows
FROM   dbo.Fact_AML_Alerts a
LEFT JOIN dbo.Fact_Transactions t ON t.Transaction_Key = a.Transaction_Key
WHERE  a.Transaction_Key IS NOT NULL AND t.Transaction_Key IS NULL;

/* DQ-X02: Cases marked closed but missing a close date */
SELECT 'DQ-X02 Closed case w/o close date' AS Check_Name, COUNT(*) AS Failing_Rows
FROM   dbo.Fact_STR_Cases c
JOIN   dbo.Dim_Status s ON s.Status_Key = c.Status_Key
WHERE  s.Is_Terminal = 1 AND c.Close_Date_Key IS NULL;

PRINT 'Data quality checks complete.';
GO
