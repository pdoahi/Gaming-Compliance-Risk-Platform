/* ============================================================================
   Phase 3 — ETL Staging Layer
   Gaming Compliance & Risk Intelligence Platform
   Target: Microsoft SQL Server (T-SQL)

   Staging tables land raw source data 1:1 before transformation into the
   star schema. They are truncate-and-reload on each batch. Minimal typing,
   no business logic, no referential integrity (raw landing zone).
   ============================================================================ */

/* ----------------------------------------------------------------------------
   stg_Transactions — raw landing for IBM AML transaction CSV.
   Column names mirror the source export. All wide/loose types; cleansing and
   surrogate-key lookups happen in the load procedure below.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.stg_Transactions', 'U') IS NOT NULL DROP TABLE dbo.stg_Transactions;
GO
CREATE TABLE dbo.stg_Transactions (
    Src_Timestamp      VARCHAR(50)  NULL,
    From_Bank          VARCHAR(50)  NULL,
    From_Account       VARCHAR(50)  NULL,
    To_Bank            VARCHAR(50)  NULL,
    To_Account         VARCHAR(50)  NULL,
    Amount_Paid        VARCHAR(50)  NULL,
    Payment_Currency   VARCHAR(20)  NULL,
    Amount_Received    VARCHAR(50)  NULL,
    Receiving_Currency VARCHAR(20)  NULL,
    Payment_Format     VARCHAR(30)  NULL,
    Is_Laundering      VARCHAR(5)   NULL,
    LoadBatchID        INT          NULL,
    LoadDate           DATETIME     NOT NULL CONSTRAINT DF_stgTxn_Load DEFAULT (GETDATE())
);
GO

/* ----------------------------------------------------------------------------
   stg_MarketPerformance — raw landing for synthetic monthly market dataset.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.stg_MarketPerformance', 'U') IS NOT NULL DROP TABLE dbo.stg_MarketPerformance;
GO
CREATE TABLE dbo.stg_MarketPerformance (
    Reporting_Period       VARCHAR(20) NULL,
    Total_Wagers           VARCHAR(50) NULL,
    Total_GGR              VARCHAR(50) NULL,
    Active_Player_Accounts VARCHAR(50) NULL,
    LoadBatchID            INT         NULL,
    LoadDate               DATETIME    NOT NULL CONSTRAINT DF_stgMkt_Load DEFAULT (GETDATE())
);
GO

/* ============================================================================
   ETL LOAD LOGIC — staging -> analytics
   ============================================================================ */

/* ----------------------------------------------------------------------------
   usp_Load_Fact_Transactions
   Transformation logic:
     1. Cast text amounts/timestamps to typed values.
     2. Resolve Account_ID -> Account_Key (auto-create missing accounts).
     3. Derive Date_Key (YYYYMMDD) and Transaction_Direction.
     4. Error handling via TRY/CATCH; reconciliation row counts at the end.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.usp_Load_Fact_Transactions', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Load_Fact_Transactions;
GO
CREATE PROCEDURE dbo.usp_Load_Fact_Transactions
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        /* Auto-create any accounts seen in staging but missing from Dim_Account */
        INSERT INTO dbo.Dim_Account (Account_ID, Home_Bank, SourceSystem)
        SELECT DISTINCT s.From_Account, s.From_Bank, 'IBM_AML'
        FROM   dbo.stg_Transactions s
        WHERE  s.From_Account IS NOT NULL
          AND  NOT EXISTS (SELECT 1 FROM dbo.Dim_Account d WHERE d.Account_ID = s.From_Account);

        /* Load transactions, resolving surrogate keys */
        INSERT INTO dbo.Fact_Transactions
            (Date_Key, Account_Key, Counterparty_Account_Key, Transaction_Timestamp,
             Amount, Currency, Payment_Format, Transaction_Direction, Is_Laundering, SourceSystem)
        SELECT
            CONVERT(INT, FORMAT(TRY_CONVERT(DATETIME, s.Src_Timestamp), 'yyyyMMdd')) AS Date_Key,
            da.Account_Key,
            dac.Account_Key,
            TRY_CONVERT(DATETIME, s.Src_Timestamp),
            TRY_CONVERT(DECIMAL(18,2), s.Amount_Paid),
            COALESCE(NULLIF(s.Payment_Currency, ''), 'CAD'),
            s.Payment_Format,
            CASE WHEN s.From_Account = s.To_Account THEN 'Transfer'
                 WHEN s.To_Account IS NULL THEN 'Withdrawal'
                 ELSE 'Transfer' END,
            CASE WHEN TRY_CONVERT(INT, s.Is_Laundering) = 1 THEN 1 ELSE 0 END,
            'IBM_AML'
        FROM dbo.stg_Transactions s
        LEFT JOIN dbo.Dim_Account da  ON da.Account_ID  = s.From_Account
        LEFT JOIN dbo.Dim_Account dac ON dac.Account_ID = s.To_Account
        WHERE TRY_CONVERT(DATETIME, s.Src_Timestamp) IS NOT NULL;  -- reject bad timestamps

        DECLARE @stg INT = (SELECT COUNT(*) FROM dbo.stg_Transactions);
        DECLARE @loaded INT = @@ROWCOUNT;
        PRINT CONCAT('Reconciliation — staging rows: ', @stg, ' | loaded: ', @loaded,
                     ' | rejected: ', @stg - @loaded);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT CONCAT('ETL error: ', ERROR_MESSAGE());
        THROW;
    END CATCH
END;
GO

/* ----------------------------------------------------------------------------
   usp_Load_Fact_MarketPerformance
   Casts text figures, derives Date_Key (first of month), computes Hold % and
   GGR-per-active-account, and (idempotent) skips periods already loaded.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.usp_Load_Fact_MarketPerformance', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Load_Fact_MarketPerformance;
GO
CREATE PROCEDURE dbo.usp_Load_Fact_MarketPerformance
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO dbo.Fact_MarketPerformance
            (Date_Key, Reporting_Period, Total_Wagers, Total_GGR,
             Active_Player_Accounts, GGR_Per_Active_Account, Hold_Percentage)
        SELECT
            CONVERT(INT, REPLACE(s.Reporting_Period, '-', '') + '01') AS Date_Key,
            s.Reporting_Period,
            TRY_CONVERT(DECIMAL(18,2), s.Total_Wagers),
            TRY_CONVERT(DECIMAL(18,2), s.Total_GGR),
            TRY_CONVERT(INT, s.Active_Player_Accounts),
            CASE WHEN TRY_CONVERT(INT, s.Active_Player_Accounts) > 0
                 THEN TRY_CONVERT(DECIMAL(18,2), s.Total_GGR) / TRY_CONVERT(INT, s.Active_Player_Accounts)
                 END,
            CASE WHEN TRY_CONVERT(DECIMAL(18,2), s.Total_Wagers) > 0
                 THEN 100.0 * TRY_CONVERT(DECIMAL(18,2), s.Total_GGR) / TRY_CONVERT(DECIMAL(18,2), s.Total_Wagers)
                 END
        FROM dbo.stg_MarketPerformance s
        WHERE NOT EXISTS (SELECT 1 FROM dbo.Fact_MarketPerformance f
                          WHERE f.Reporting_Period = s.Reporting_Period);
        PRINT CONCAT('Market rows loaded: ', @@ROWCOUNT);
    END TRY
    BEGIN CATCH
        PRINT CONCAT('ETL error: ', ERROR_MESSAGE());
        THROW;
    END CATCH
END;
GO

PRINT 'Staging tables and load procedures created.';
GO
