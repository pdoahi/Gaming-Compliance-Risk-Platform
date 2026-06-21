/* ============================================================================
   Phase 3 — Schema Creation: FACTS
   Gaming Compliance & Risk Intelligence Platform
   Target: Microsoft SQL Server (T-SQL)

   Creates the 4 fact tables. Run AFTER 01_create_dimensions.sql.
   Compliance lifecycle chain: Fact_Transactions -> Fact_AML_Alerts -> Fact_STR_Cases
   Fact_MarketPerformance is standalone (monthly grain, joins Dim_Date only).
   ============================================================================ */

/* ----------------------------------------------------------------------------
   Fact_Transactions
   Grain: one row per transaction. Core fact AML rules evaluate.
   Role-playing Dim_Account: Account_Key (originating) + Counterparty_Account_Key.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.Fact_Transactions', 'U') IS NOT NULL DROP TABLE dbo.Fact_Transactions;
GO
CREATE TABLE dbo.Fact_Transactions (
    Transaction_Key           BIGINT        IDENTITY(1,1) NOT NULL,
    Date_Key                  INT           NOT NULL,
    Account_Key               INT           NOT NULL,
    Counterparty_Account_Key  INT           NULL,
    Player_Key                INT           NULL,
    Transaction_Timestamp     DATETIME      NOT NULL,
    Amount                    DECIMAL(18,2) NOT NULL,
    Currency                  VARCHAR(3)    NOT NULL CONSTRAINT DF_FactTxn_Ccy DEFAULT ('CAD'),
    Payment_Format            VARCHAR(30)   NULL,
    Transaction_Direction     VARCHAR(10)   NULL,
    Is_Laundering             BIT           NOT NULL CONSTRAINT DF_FactTxn_Laund DEFAULT (0),
    PEP_Flag                  BIT           NOT NULL CONSTRAINT DF_FactTxn_PEP DEFAULT (0),
    Sanctions_Flag            BIT           NOT NULL CONSTRAINT DF_FactTxn_Sanc DEFAULT (0),
    SourceSystem              VARCHAR(30)   NOT NULL CONSTRAINT DF_FactTxn_Src DEFAULT ('Synthetic'),
    CreatedDate               DATETIME      NOT NULL CONSTRAINT DF_FactTxn_Created DEFAULT (GETDATE()),
    CONSTRAINT PK_Fact_Transactions PRIMARY KEY CLUSTERED (Transaction_Key),
    CONSTRAINT FK_FactTxn_Date       FOREIGN KEY (Date_Key)                 REFERENCES dbo.Dim_Date (Date_Key),
    CONSTRAINT FK_FactTxn_Account    FOREIGN KEY (Account_Key)              REFERENCES dbo.Dim_Account (Account_Key),
    CONSTRAINT FK_FactTxn_Counter    FOREIGN KEY (Counterparty_Account_Key) REFERENCES dbo.Dim_Account (Account_Key),
    CONSTRAINT FK_FactTxn_Player     FOREIGN KEY (Player_Key)              REFERENCES dbo.Dim_Player (Player_Key),
    CONSTRAINT CK_FactTxn_Amount     CHECK (Amount >= 0),
    CONSTRAINT CK_FactTxn_Direction  CHECK (Transaction_Direction IN ('Deposit','Withdrawal','Transfer'))
);
GO

/* ----------------------------------------------------------------------------
   Fact_AML_Alerts
   Grain: one row per alert (transaction x rule). Bridge between raw
   transactions and case investigations. Risk_Score/Severity from Phase 5.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.Fact_AML_Alerts', 'U') IS NOT NULL DROP TABLE dbo.Fact_AML_Alerts;
GO
CREATE TABLE dbo.Fact_AML_Alerts (
    Alert_Key        BIGINT       IDENTITY(1,1) NOT NULL,
    Transaction_Key  BIGINT       NULL,
    AlertType_Key    INT          NOT NULL,
    Account_Key      INT          NULL,
    Player_Key       INT          NULL,
    Date_Key         INT          NOT NULL,
    Status_Key       INT          NOT NULL,
    Risk_Score       INT          NOT NULL CONSTRAINT DF_FactAlert_Score DEFAULT (0),
    Severity         VARCHAR(10)  NOT NULL CONSTRAINT DF_FactAlert_Sev DEFAULT ('Medium'),
    Alert_Timestamp  DATETIME     NOT NULL CONSTRAINT DF_FactAlert_TS DEFAULT (GETDATE()),
    Is_Escalated     BIT          NOT NULL CONSTRAINT DF_FactAlert_Esc DEFAULT (0),
    SourceSystem     VARCHAR(30)  NOT NULL CONSTRAINT DF_FactAlert_Src DEFAULT ('AML_Engine'),
    CreatedDate      DATETIME     NOT NULL CONSTRAINT DF_FactAlert_Created DEFAULT (GETDATE()),
    ModifiedDate     DATETIME     NULL,
    CONSTRAINT PK_Fact_AML_Alerts PRIMARY KEY CLUSTERED (Alert_Key),
    CONSTRAINT FK_FactAlert_Txn      FOREIGN KEY (Transaction_Key) REFERENCES dbo.Fact_Transactions (Transaction_Key),
    CONSTRAINT FK_FactAlert_Type     FOREIGN KEY (AlertType_Key)   REFERENCES dbo.Dim_AlertType (AlertType_Key),
    CONSTRAINT FK_FactAlert_Account  FOREIGN KEY (Account_Key)     REFERENCES dbo.Dim_Account (Account_Key),
    CONSTRAINT FK_FactAlert_Player   FOREIGN KEY (Player_Key)      REFERENCES dbo.Dim_Player (Player_Key),
    CONSTRAINT FK_FactAlert_Date     FOREIGN KEY (Date_Key)        REFERENCES dbo.Dim_Date (Date_Key),
    CONSTRAINT FK_FactAlert_Status   FOREIGN KEY (Status_Key)      REFERENCES dbo.Dim_Status (Status_Key),
    CONSTRAINT CK_FactAlert_Score    CHECK (Risk_Score BETWEEN 0 AND 100),
    CONSTRAINT CK_FactAlert_Sev      CHECK (Severity IN ('Low','Medium','High','Critical'))
);
GO

/* ----------------------------------------------------------------------------
   Fact_STR_Cases
   Grain: one row per investigation case. Heart of STR workflow & SLA reporting.
   Largely synthetic case metadata, linked to real alerts.
   Two role-playing dates: Open_Date_Key + Close_Date_Key (nullable, open cases).
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.Fact_STR_Cases', 'U') IS NOT NULL DROP TABLE dbo.Fact_STR_Cases;
GO
CREATE TABLE dbo.Fact_STR_Cases (
    Case_Key            BIGINT       IDENTITY(1,1) NOT NULL,
    Alert_Key           BIGINT       NOT NULL,
    Analyst_Key         INT          NULL,
    Player_Key          INT          NULL,
    Status_Key          INT          NOT NULL,
    Open_Date_Key       INT          NOT NULL,
    Close_Date_Key      INT          NULL,
    Case_Priority       VARCHAR(10)  NOT NULL CONSTRAINT DF_FactCase_Pri DEFAULT ('Medium'),
    SLA_Days            INT          NOT NULL CONSTRAINT DF_FactCase_SLA DEFAULT (10),
    Investigation_Days  INT          NULL,
    SLA_Breached        BIT          NOT NULL CONSTRAINT DF_FactCase_Breach DEFAULT (0),
    STR_Submitted_Flag  BIT          NOT NULL CONSTRAINT DF_FactCase_STR DEFAULT (0),
    Closure_Reason      VARCHAR(50)  NULL,
    SourceSystem        VARCHAR(30)  NOT NULL CONSTRAINT DF_FactCase_Src DEFAULT ('Synthetic'),
    CreatedDate         DATETIME     NOT NULL CONSTRAINT DF_FactCase_Created DEFAULT (GETDATE()),
    ModifiedDate        DATETIME     NULL,
    CONSTRAINT PK_Fact_STR_Cases PRIMARY KEY CLUSTERED (Case_Key),
    CONSTRAINT FK_FactCase_Alert    FOREIGN KEY (Alert_Key)      REFERENCES dbo.Fact_AML_Alerts (Alert_Key),
    CONSTRAINT FK_FactCase_Analyst  FOREIGN KEY (Analyst_Key)    REFERENCES dbo.Dim_Analyst (Analyst_Key),
    CONSTRAINT FK_FactCase_Player   FOREIGN KEY (Player_Key)     REFERENCES dbo.Dim_Player (Player_Key),
    CONSTRAINT FK_FactCase_Status   FOREIGN KEY (Status_Key)     REFERENCES dbo.Dim_Status (Status_Key),
    CONSTRAINT FK_FactCase_OpenDt   FOREIGN KEY (Open_Date_Key)  REFERENCES dbo.Dim_Date (Date_Key),
    CONSTRAINT FK_FactCase_CloseDt  FOREIGN KEY (Close_Date_Key) REFERENCES dbo.Dim_Date (Date_Key),
    CONSTRAINT CK_FactCase_Pri      CHECK (Case_Priority IN ('Low','Medium','High','Critical'))
);
GO

/* ----------------------------------------------------------------------------
   Fact_MarketPerformance
   Grain: one row per reporting month. Synthetic market metrics for GGR
   reporting & executive dashboards. Joins Dim_Date only (standalone).
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.Fact_MarketPerformance', 'U') IS NOT NULL DROP TABLE dbo.Fact_MarketPerformance;
GO
CREATE TABLE dbo.Fact_MarketPerformance (
    MarketPerf_Key          INT           IDENTITY(1,1) NOT NULL,
    Date_Key                INT           NOT NULL,
    Reporting_Period        VARCHAR(7)    NOT NULL,
    Total_Wagers            DECIMAL(18,2) NOT NULL,
    Total_GGR               DECIMAL(18,2) NOT NULL,
    Active_Player_Accounts  INT           NOT NULL,
    GGR_Per_Active_Account  DECIMAL(18,2) NULL,
    Hold_Percentage         DECIMAL(5,2)  NULL,
    MoM_GGR_Growth          DECIMAL(6,2)  NULL,
    SourceSystem            VARCHAR(30)   NOT NULL CONSTRAINT DF_FactMkt_Src DEFAULT ('Synthetic_Market'),
    CreatedDate             DATETIME      NOT NULL CONSTRAINT DF_FactMkt_Created DEFAULT (GETDATE()),
    CONSTRAINT PK_Fact_MarketPerformance PRIMARY KEY CLUSTERED (MarketPerf_Key),
    CONSTRAINT FK_FactMkt_Date FOREIGN KEY (Date_Key) REFERENCES dbo.Dim_Date (Date_Key),
    CONSTRAINT UQ_FactMkt_Period UNIQUE (Reporting_Period),
    CONSTRAINT CK_FactMkt_Wagers CHECK (Total_Wagers >= 0),
    CONSTRAINT CK_FactMkt_Active CHECK (Active_Player_Accounts >= 0)
);
GO

PRINT 'Facts created: Fact_Transactions, Fact_AML_Alerts, Fact_STR_Cases, Fact_MarketPerformance';
GO
