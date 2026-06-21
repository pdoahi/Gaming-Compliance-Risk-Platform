/* ============================================================================
   Phase 5 — AML Rule Detection Views
   Gaming Compliance & Risk Intelligence Platform
   Target: Microsoft SQL Server (T-SQL)

   One view per rule. Each returns the triggering Transaction_Key plus the
   AlertType_Key, so the consolidated generator (03) can union them and insert
   into Fact_AML_Alerts. Views are intentionally simple and easy to tune:
   thresholds live in the WHERE/HAVING clauses with comments.

   Run after: schema, data load, 01_populate_dim_alerttype.sql
   ============================================================================ */

/* ---- AML-R01: Large Transaction Detection (>= 10,000) ---- */
IF OBJECT_ID('dbo.vw_rule_R01_large_txn','V') IS NOT NULL DROP VIEW dbo.vw_rule_R01_large_txn;
GO
CREATE VIEW dbo.vw_rule_R01_large_txn AS
SELECT t.Transaction_Key, 1 AS AlertType_Key
FROM dbo.Fact_Transactions t
WHERE t.Amount >= 10000;          -- FINTRAC large-transaction reference
GO

/* ---- AML-R02: Structuring (>=3 in [9000,10000) per account / 7 days) ---- */
IF OBJECT_ID('dbo.vw_rule_R02_structuring','V') IS NOT NULL DROP VIEW dbo.vw_rule_R02_structuring;
GO
CREATE VIEW dbo.vw_rule_R02_structuring AS
WITH banded AS (
    SELECT Transaction_Key, Account_Key, Transaction_Timestamp
    FROM dbo.Fact_Transactions
    WHERE Amount >= 9000 AND Amount < 10000          -- just-under-threshold band
),
cnt AS (
    SELECT b.Transaction_Key, b.Account_Key,
           COUNT(*) OVER (PARTITION BY b.Account_Key) AS band_cnt   -- per-account band volume
    FROM banded b
)
SELECT Transaction_Key, 2 AS AlertType_Key
FROM cnt
WHERE band_cnt >= 3;             -- 7-day windowing applied in batch ETL; simplified here
GO

/* ---- AML-R03: Rapid Movement (deposit then >=90% withdrawal within 6h) ---- */
IF OBJECT_ID('dbo.vw_rule_R03_rapid_movement','V') IS NOT NULL DROP VIEW dbo.vw_rule_R03_rapid_movement;
GO
CREATE VIEW dbo.vw_rule_R03_rapid_movement AS
SELECT w.Transaction_Key, 3 AS AlertType_Key
FROM dbo.Fact_Transactions d
JOIN dbo.Fact_Transactions w
  ON w.Account_Key = d.Account_Key                            -- same player wallet
 AND d.Transaction_Direction = 'Deposit'
 AND w.Transaction_Direction = 'Withdrawal'
 AND w.Transaction_Timestamp > d.Transaction_Timestamp
 AND w.Transaction_Timestamp <= DATEADD(HOUR, 6, d.Transaction_Timestamp)
 AND w.Amount >= 0.90 * d.Amount;                             -- near-equal pass-through
GO

/* ---- AML-R04: High Velocity (>=8 txns per account / 24h) ---- */
IF OBJECT_ID('dbo.vw_rule_R04_velocity','V') IS NOT NULL DROP VIEW dbo.vw_rule_R04_velocity;
GO
CREATE VIEW dbo.vw_rule_R04_velocity AS
WITH daily AS (
    SELECT Transaction_Key, Account_Key, Date_Key,
           COUNT(*) OVER (PARTITION BY Account_Key, Date_Key) AS day_cnt
    FROM dbo.Fact_Transactions
)
SELECT Transaction_Key, 4 AS AlertType_Key
FROM daily WHERE day_cnt >= 8;
GO

/* ---- AML-R05: Sub-Threshold Multiple (>=5 txns < 10,000 per account / day) ---- */
IF OBJECT_ID('dbo.vw_rule_R05_subthreshold','V') IS NOT NULL DROP VIEW dbo.vw_rule_R05_subthreshold;
GO
CREATE VIEW dbo.vw_rule_R05_subthreshold AS
WITH small AS (
    SELECT Transaction_Key, Account_Key, Date_Key,
           COUNT(*) OVER (PARTITION BY Account_Key, Date_Key) AS small_cnt
    FROM dbo.Fact_Transactions
    WHERE Amount < 10000
)
SELECT Transaction_Key, 5 AS AlertType_Key
FROM small WHERE small_cnt >= 5;
GO

/* ---- AML-R06: High-Risk Payment Method (Crypto/Prepaid Card >= 5,000) ---- */
IF OBJECT_ID('dbo.vw_rule_R06_highrisk_format','V') IS NOT NULL DROP VIEW dbo.vw_rule_R06_highrisk_format;
GO
CREATE VIEW dbo.vw_rule_R06_highrisk_format AS
SELECT Transaction_Key, 6 AS AlertType_Key
FROM dbo.Fact_Transactions
WHERE Payment_Format IN ('Crypto','Prepaid Card') AND Amount >= 5000;
GO

/* ---- AML-R07: Unusual Activity Spike (daily total >= 5x account median, >=5,000) ---- */
IF OBJECT_ID('dbo.vw_rule_R07_spike','V') IS NOT NULL DROP VIEW dbo.vw_rule_R07_spike;
GO
CREATE VIEW dbo.vw_rule_R07_spike AS
WITH daily AS (
    SELECT Account_Key, Date_Key, SUM(Amount) AS day_total
    FROM dbo.Fact_Transactions GROUP BY Account_Key, Date_Key
),
med AS (   -- median daily total per account (PERCENTILE_CONT)
    SELECT DISTINCT Account_Key,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY day_total)
               OVER (PARTITION BY Account_Key) AS median_day
    FROM daily
)
SELECT t.Transaction_Key, 7 AS AlertType_Key
FROM dbo.Fact_Transactions t
JOIN daily d ON d.Account_Key = t.Account_Key AND d.Date_Key = t.Date_Key
JOIN med   m ON m.Account_Key = t.Account_Key
WHERE d.day_total >= 5000 AND m.median_day > 0 AND d.day_total >= 5 * m.median_day;
GO

/* ---- AML-R08: Dormant Reactivation (gap >= 30 days then >= 5,000) ---- */
IF OBJECT_ID('dbo.vw_rule_R08_dormant','V') IS NOT NULL DROP VIEW dbo.vw_rule_R08_dormant;
GO
CREATE VIEW dbo.vw_rule_R08_dormant AS
WITH seq AS (
    SELECT Transaction_Key, Account_Key, Amount, Transaction_Timestamp,
           LAG(Transaction_Timestamp) OVER (PARTITION BY Account_Key ORDER BY Transaction_Timestamp) AS prev_ts
    FROM dbo.Fact_Transactions
)
SELECT Transaction_Key, 8 AS AlertType_Key
FROM seq
WHERE prev_ts IS NOT NULL
  AND DATEDIFF(DAY, prev_ts, Transaction_Timestamp) >= 30
  AND Amount >= 5000;
GO

/* ---- AML-R09: Round-Number Large (>=10,000 and multiple of 1,000) ---- */
IF OBJECT_ID('dbo.vw_rule_R09_round_number','V') IS NOT NULL DROP VIEW dbo.vw_rule_R09_round_number;
GO
CREATE VIEW dbo.vw_rule_R09_round_number AS
SELECT Transaction_Key, 9 AS AlertType_Key
FROM dbo.Fact_Transactions
WHERE Amount >= 10000 AND Amount % 1000 = 0;
GO

/* ---- AML-R10: Counterparty Concentration (>=4 txns to same payee >= 20,000 / 30d) ---- */
IF OBJECT_ID('dbo.vw_rule_R10_concentration','V') IS NOT NULL DROP VIEW dbo.vw_rule_R10_concentration;
GO
CREATE VIEW dbo.vw_rule_R10_concentration AS
WITH pair AS (
    SELECT Transaction_Key, Account_Key, Counterparty_Account_Key, Amount,
           COUNT(*)   OVER (PARTITION BY Account_Key, Counterparty_Account_Key) AS pair_cnt,
           SUM(Amount) OVER (PARTITION BY Account_Key, Counterparty_Account_Key) AS pair_sum
    FROM dbo.Fact_Transactions
    WHERE Counterparty_Account_Key IS NOT NULL
)
SELECT Transaction_Key, 10 AS AlertType_Key
FROM pair
WHERE pair_cnt >= 4 AND pair_sum >= 20000;   -- 30-day window applied in batch ETL
GO

/* ---- AML-R11: Sanctions / Watchlist Match (any activity by a flagged account) ---- */
IF OBJECT_ID('dbo.vw_rule_R11_sanctions','V') IS NOT NULL DROP VIEW dbo.vw_rule_R11_sanctions;
GO
CREATE VIEW dbo.vw_rule_R11_sanctions AS
SELECT Transaction_Key, 11 AS AlertType_Key
FROM dbo.Fact_Transactions
WHERE Sanctions_Flag = 1;
GO

PRINT '11 AML rule views created.';
GO
