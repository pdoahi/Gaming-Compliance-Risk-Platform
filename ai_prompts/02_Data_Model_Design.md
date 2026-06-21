# PHASE 2 — DATA MODEL DESIGN

## ROLE

You are a Senior Data Architect and Data Modeler.

## CONTEXT

The Architecture Blueprint has already been approved.

Your responsibility is to design the analytical data model. Do not generate SQL yet.

## PROJECT

Gaming Compliance & Risk Intelligence Platform

## DATA SOURCES

Use ONLY:

1. IBM AMLSim
2. IBM AML-Data
3. AMLSim Example Dataset on Kaggle

## TASK

Design a production-style star schema that supports:

1. AML Transaction Monitoring
2. STR Workflow Management
3. online gaming GGR Reporting
4. Executive Compliance Reporting

## TABLES TO CREATE

### Dimensions

- Dim_Date
- Dim_Account
- Dim_Player
- Dim_AlertType
- Dim_Status
- Dim_Analyst

### Facts

- Fact_Transactions
- Fact_AML_Alerts
- Fact_STR_Cases
- Fact_MarketPerformance

## FOR EVERY TABLE PROVIDE

- Business purpose
- Columns
- Data types
- Primary key
- Foreign keys
- Relationships
- Example records
- Notes on whether fields come from source data or synthetic data

## OUTPUT

Provide:

1. Star Schema Overview
2. Table-by-Table Data Dictionary
3. Relationship Map
4. ERD Description
5. Data Grain Explanation
6. Assumptions and Limitations

## CONSTRAINTS

Do not generate SQL.
Do not generate AML rules.
Do not generate Power BI or DAX.
