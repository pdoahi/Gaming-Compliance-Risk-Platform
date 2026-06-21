/* ============================================================================
   Phase 3 — Schema Creation: DIMENSIONS
   Gaming Compliance & Risk Intelligence Platform
   Target: Microsoft SQL Server (T-SQL)

   Creates the 6 dimension tables of the star schema. Run this BEFORE the
   fact tables (02_create_facts.sql), since facts reference these via FK.
   ============================================================================ */

/* ----------------------------------------------------------------------------
   Dim_Date
   Business purpose: standard calendar dimension for time-based analysis and
   period-over-period growth across all facts. Date_Key is YYYYMMDD.
   Note: Day/Month/Year are bracketed to avoid collision with T-SQL functions.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.Dim_Date', 'U') IS NOT NULL DROP TABLE dbo.Dim_Date;
GO
CREATE TABLE dbo.Dim_Date (
    Date_Key      INT          NOT NULL,
    Full_Date     DATE         NOT NULL,
    [Day]         TINYINT      NOT NULL,
    [Month]       TINYINT      NOT NULL,
    Month_Name    VARCHAR(20)  NOT NULL,
    [Quarter]     TINYINT      NOT NULL,
    [Year]        SMALLINT     NOT NULL,
    Year_Month    VARCHAR(7)   NOT NULL,
    Day_Of_Week   VARCHAR(10)  NOT NULL,
    Is_Weekend    BIT          NOT NULL CONSTRAINT DF_DimDate_IsWeekend DEFAULT (0),
    Fiscal_Year   SMALLINT     NOT NULL,
    CreatedDate   DATETIME     NOT NULL CONSTRAINT DF_DimDate_Created DEFAULT (GETDATE()),
    CONSTRAINT PK_Dim_Date PRIMARY KEY CLUSTERED (Date_Key)
);
GO

/* ----------------------------------------------------------------------------
   Dim_Player
   Business purpose: the customer behind one or more accounts. Supports KYC and
   player-level AML aggregation. Created before Dim_Account (Account FKs to it).
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.Dim_Player', 'U') IS NOT NULL DROP TABLE dbo.Dim_Player;
GO
CREATE TABLE dbo.Dim_Player (
    Player_Key          INT          IDENTITY(1,1) NOT NULL,
    Player_ID           VARCHAR(50)  NOT NULL,
    Registration_Date   DATE         NULL,
    Province            VARCHAR(30)  NOT NULL CONSTRAINT DF_DimPlayer_Prov DEFAULT ('Region-A'),
    KYC_Status          VARCHAR(20)  NOT NULL CONSTRAINT DF_DimPlayer_KYC DEFAULT ('Pending'),
    KYC_Risk_Level      VARCHAR(10)  NOT NULL CONSTRAINT DF_DimPlayer_Risk DEFAULT ('Low'),
    PEP_Flag            BIT          NOT NULL CONSTRAINT DF_DimPlayer_PEP DEFAULT (0),
    Self_Exclusion_Flag BIT          NOT NULL CONSTRAINT DF_DimPlayer_SE DEFAULT (0),
    SourceSystem        VARCHAR(30)  NOT NULL CONSTRAINT DF_DimPlayer_Src DEFAULT ('Synthetic'),
    CreatedDate         DATETIME     NOT NULL CONSTRAINT DF_DimPlayer_Created DEFAULT (GETDATE()),
    ModifiedDate        DATETIME     NULL,
    CONSTRAINT PK_Dim_Player PRIMARY KEY CLUSTERED (Player_Key),
    CONSTRAINT UQ_Dim_Player_PlayerID UNIQUE (Player_ID),
    CONSTRAINT CK_DimPlayer_KYCRisk CHECK (KYC_Risk_Level IN ('Low','Medium','High'))
);
GO

/* ----------------------------------------------------------------------------
   Dim_Account
   Business purpose: the financial/gaming accounts in transactions. Conformed
   dimension shared by Fact_Transactions and Fact_AML_Alerts.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.Dim_Account', 'U') IS NOT NULL DROP TABLE dbo.Dim_Account;
GO
CREATE TABLE dbo.Dim_Account (
    Account_Key       INT          IDENTITY(1,1) NOT NULL,
    Account_ID        VARCHAR(50)  NOT NULL,
    Player_Key        INT          NULL,
    Account_Type      VARCHAR(30)  NOT NULL CONSTRAINT DF_DimAcct_Type DEFAULT ('Player Wallet'),
    Account_Open_Date DATE         NULL,
    Account_Status    VARCHAR(20)  NOT NULL CONSTRAINT DF_DimAcct_Status DEFAULT ('Active'),
    Home_Bank         VARCHAR(50)  NULL,
    Risk_Rating       VARCHAR(10)  NOT NULL CONSTRAINT DF_DimAcct_Risk DEFAULT ('Low'),
    SourceSystem      VARCHAR(30)  NOT NULL CONSTRAINT DF_DimAcct_Src DEFAULT ('IBM_AML'),
    CreatedDate       DATETIME     NOT NULL CONSTRAINT DF_DimAcct_Created DEFAULT (GETDATE()),
    ModifiedDate      DATETIME     NULL,
    CONSTRAINT PK_Dim_Account PRIMARY KEY CLUSTERED (Account_Key),
    CONSTRAINT UQ_Dim_Account_AccountID UNIQUE (Account_ID),
    CONSTRAINT FK_DimAccount_Player FOREIGN KEY (Player_Key) REFERENCES dbo.Dim_Player (Player_Key),
    CONSTRAINT CK_DimAcct_Status CHECK (Account_Status IN ('Active','Dormant','Closed'))
);
GO

/* ----------------------------------------------------------------------------
   Dim_AlertType
   Business purpose: reference dimension of AML rules/typologies. Drives
   "alerts by rule" analysis. Populated with ~10 rules in Phase 5.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.Dim_AlertType', 'U') IS NOT NULL DROP TABLE dbo.Dim_AlertType;
GO
CREATE TABLE dbo.Dim_AlertType (
    AlertType_Key     INT          IDENTITY(1,1) NOT NULL,
    Rule_Code         VARCHAR(20)  NOT NULL,
    Rule_Name         VARCHAR(100) NOT NULL,
    Typology          VARCHAR(50)  NULL,
    Default_Severity  VARCHAR(10)  NOT NULL CONSTRAINT DF_DimAlert_Sev DEFAULT ('Medium'),
    Base_Risk_Score   INT          NOT NULL CONSTRAINT DF_DimAlert_Score DEFAULT (50),
    [Description]     VARCHAR(255) NULL,
    CreatedDate       DATETIME     NOT NULL CONSTRAINT DF_DimAlert_Created DEFAULT (GETDATE()),
    CONSTRAINT PK_Dim_AlertType PRIMARY KEY CLUSTERED (AlertType_Key),
    CONSTRAINT UQ_Dim_AlertType_RuleCode UNIQUE (Rule_Code),
    CONSTRAINT CK_DimAlert_Sev CHECK (Default_Severity IN ('Low','Medium','High','Critical')),
    CONSTRAINT CK_DimAlert_Score CHECK (Base_Risk_Score BETWEEN 0 AND 100)
);
GO

/* ----------------------------------------------------------------------------
   Dim_Status
   Business purpose: alert/case lifecycle statuses for STR workflow stage
   analysis. Workflow_Order supports funnel ordering.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.Dim_Status', 'U') IS NOT NULL DROP TABLE dbo.Dim_Status;
GO
CREATE TABLE dbo.Dim_Status (
    Status_Key      INT          IDENTITY(1,1) NOT NULL,
    Status_Code     VARCHAR(20)  NOT NULL,
    Status_Name     VARCHAR(50)  NOT NULL,
    Status_Category VARCHAR(20)  NOT NULL CONSTRAINT DF_DimStatus_Cat DEFAULT ('Open'),
    Workflow_Order  TINYINT      NOT NULL CONSTRAINT DF_DimStatus_Order DEFAULT (1),
    Is_Terminal     BIT          NOT NULL CONSTRAINT DF_DimStatus_Term DEFAULT (0),
    CreatedDate     DATETIME     NOT NULL CONSTRAINT DF_DimStatus_Created DEFAULT (GETDATE()),
    CONSTRAINT PK_Dim_Status PRIMARY KEY CLUSTERED (Status_Key),
    CONSTRAINT UQ_Dim_Status_Code UNIQUE (Status_Code),
    CONSTRAINT CK_DimStatus_Cat CHECK (Status_Category IN ('Open','Closed'))
);
GO

/* ----------------------------------------------------------------------------
   Dim_Analyst
   Business purpose: compliance analysts who own cases. Enables workload,
   productivity, and per-analyst SLA analysis. Synthetic data.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.Dim_Analyst', 'U') IS NOT NULL DROP TABLE dbo.Dim_Analyst;
GO
CREATE TABLE dbo.Dim_Analyst (
    Analyst_Key   INT          IDENTITY(1,1) NOT NULL,
    Analyst_ID    VARCHAR(20)  NOT NULL,
    Analyst_Name  VARCHAR(100) NOT NULL,
    Team          VARCHAR(50)  NULL,
    Seniority     VARCHAR(20)  NOT NULL CONSTRAINT DF_DimAnalyst_Sen DEFAULT ('Junior'),
    Active_Flag   BIT          NOT NULL CONSTRAINT DF_DimAnalyst_Active DEFAULT (1),
    SourceSystem  VARCHAR(30)  NOT NULL CONSTRAINT DF_DimAnalyst_Src DEFAULT ('Synthetic'),
    CreatedDate   DATETIME     NOT NULL CONSTRAINT DF_DimAnalyst_Created DEFAULT (GETDATE()),
    CONSTRAINT PK_Dim_Analyst PRIMARY KEY CLUSTERED (Analyst_Key),
    CONSTRAINT UQ_Dim_Analyst_ID UNIQUE (Analyst_ID),
    CONSTRAINT CK_DimAnalyst_Sen CHECK (Seniority IN ('Junior','Senior','Lead'))
);
GO

PRINT 'Dimensions created: Dim_Date, Dim_Player, Dim_Account, Dim_AlertType, Dim_Status, Dim_Analyst';
GO
