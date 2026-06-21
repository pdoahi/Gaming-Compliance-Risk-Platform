# PHASE 3 — SQL DATABASE & ANALYTICS FOUNDATION

## ROLE

You are a Principal Data Warehouse Architect, Senior SQL Developer, AML Analytics Engineer, and Business Intelligence Data Engineer.

## PROJECT

Gaming Compliance & Risk Intelligence Platform

## CONTEXT

The Architecture Blueprint and Data Model have already been approved.

Your responsibility is NOT to build AML monitoring rules yet.

Your responsibility is to build the production-ready analytics database foundation that will support:

1. AML Transaction Monitoring
2. STR Workflow Management
3. online gaming GGR Reporting
4. Executive Compliance Reporting

## DATA SOURCES

1. IBM AMLSim
2. IBM AML-Data
3. AMLSim Example Dataset

## OBJECTIVE

Design and implement a SQL analytics environment that could realistically support a Gaming operator's compliance and reporting function.

---

## PART 1 — DATABASE ARCHITECTURE

Recommend:

- OLTP vs OLAP considerations
- Data warehouse structure
- Staging layer
- Analytics layer
- Reporting layer

Provide:

- Architecture explanation
- Data flow
- Design decisions

---

## PART 2 — SCHEMA CREATION

Generate production-quality SQL Server scripts for:

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

For each table:

- CREATE TABLE statement
- Constraints
- Primary keys
- Foreign keys
- Default values
- Audit columns

Include where appropriate:

- CreatedDate
- ModifiedDate
- SourceSystem

---

## PART 3 — DATA QUALITY FRAMEWORK

Create validation checks for:

### Transactions

- Null values
- Duplicate transactions
- Invalid timestamps
- Invalid account IDs
- Negative transaction amounts

### Market Data

- Missing periods
- Invalid revenue values
- Invalid active account counts

Generate SQL validation scripts.

---

## PART 4 — ETL STAGING DESIGN

Create staging tables, including:

- stg_Transactions
- stg_MarketPerformance

Provide:

- Load logic
- Transformation logic
- Error handling
- Reconciliation checks

Explain how source data moves into fact tables.

---

## PART 5 — ANALYTICAL REPORTING VIEWS

Generate SQL views for:

- vw_TransactionSummary
- vw_AlertSummary
- vw_STRSummary
- vw_MarketPerformanceSummary
- vw_ExecutiveComplianceMetrics

For each view provide:

- SQL
- Business purpose
- Reporting use cases

---

## PART 6 — PERFORMANCE OPTIMIZATION

Recommend:

- Clustered indexes
- Non-clustered indexes
- Partitioning strategy
- View optimization
- Query optimization

Explain rationale.

---

## PART 7 — TEST DATA

Generate sample INSERT statements for:

- Transactions
- Alerts
- STR Cases
- Market Performance

Create enough data to support testing.

---

## PART 8 — PROJECT STRUCTURE

Organize deliverables into:

```text
/sql
/sql/schema
/sql/staging
/sql/views
/sql/data_quality
/sql/test_data
/sql/documentation
```

---

## IMPORTANT CONSTRAINTS

Do NOT build AML monitoring rules.
Do NOT build Power BI.
Do NOT build DAX.
Do NOT build machine learning models.

Focus exclusively on creating a robust analytics database foundation.

## OUTPUT FORMAT

Provide:

1. Architecture Overview
2. Schema Scripts
3. Data Quality Scripts
4. ETL Design
5. Reporting Views
6. Performance Recommendations
7. Folder Structure

The final output should resemble the work of a senior data engineering team preparing an analytics environment for compliance and regulatory reporting.
