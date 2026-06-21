/* ============================================================================
   Phase 6 — Seed Dim_Status and Dim_Analyst for STR workflow
   Gaming Compliance & Risk Intelligence Platform
   Target: Microsoft SQL Server (T-SQL)

   Idempotent reference-data seed. Dim_Analyst data is SYNTHETIC.
   Run after schema creation, before STR case generation.
   ============================================================================ */

/* ---- Dim_Status: the 5-stage STR workflow ---- */
MERGE dbo.Dim_Status AS tgt
USING (VALUES
    ('NEW','New','Open',1,0),
    ('REVIEW','Under Review','Open',2,0),
    ('ESC','Escalated','Open',3,0),
    ('STR_SUB','STR Submitted','Open',4,0),
    ('CLOSED','Closed','Closed',5,1)
) AS src (Status_Code, Status_Name, Status_Category, Workflow_Order, Is_Terminal)
ON tgt.Status_Code = src.Status_Code
WHEN MATCHED THEN UPDATE SET
    Status_Name = src.Status_Name, Status_Category = src.Status_Category,
    Workflow_Order = src.Workflow_Order, Is_Terminal = src.Is_Terminal
WHEN NOT MATCHED THEN
    INSERT (Status_Code, Status_Name, Status_Category, Workflow_Order, Is_Terminal)
    VALUES (src.Status_Code, src.Status_Name, src.Status_Category, src.Workflow_Order, src.Is_Terminal);

/* ---- Dim_Analyst: synthetic compliance team ---- */
MERGE dbo.Dim_Analyst AS tgt
USING (VALUES
    ('AN-001','Alex Rivera (synthetic)','AML Ops','Junior',1),
    ('AN-003','Sam Okafor (synthetic)','Investigations','Lead',1),
    ('AN-007','Jordan Vale (synthetic)','Investigations','Senior',1),
    ('AN-011','Priya Anand (synthetic)','AML Ops','Junior',1),
    ('AN-014','Mei Lin (synthetic)','Investigations','Senior',1),
    ('AN-021','Tomas Berg (synthetic)','QA','Lead',1)
) AS src (Analyst_ID, Analyst_Name, Team, Seniority, Active_Flag)
ON tgt.Analyst_ID = src.Analyst_ID
WHEN MATCHED THEN UPDATE SET
    Analyst_Name = src.Analyst_Name, Team = src.Team,
    Seniority = src.Seniority, Active_Flag = src.Active_Flag
WHEN NOT MATCHED THEN
    INSERT (Analyst_ID, Analyst_Name, Team, Seniority, Active_Flag, SourceSystem)
    VALUES (src.Analyst_ID, src.Analyst_Name, src.Team, src.Seniority, src.Active_Flag, 'Synthetic');

PRINT 'Dim_Status and Dim_Analyst seeded.';
GO
