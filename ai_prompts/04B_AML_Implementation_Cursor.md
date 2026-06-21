# PHASE 4B — AML RULE IMPLEMENTATION IN SQL

## ROLE

You are a Senior SQL Developer and AML Analytics Engineer.

## CONTEXT

The AML Monitoring Framework has been approved by the compliance/design phase.

## TASK

Implement the approved AML monitoring framework as SQL views and alert-generation logic.

## DELIVERABLES

Organize output into:

```text
/sql/aml_rules
```

Generate:

1. Rule-specific SQL views
2. A consolidated alert-generation query
3. Risk scoring logic
4. Alert severity mapping
5. Insert logic for Fact_AML_Alerts
6. Validation queries to test rule output

## REQUIREMENTS

For each AML rule:

- Create a clear SQL file
- Add comments explaining the business logic
- Make the rule easy to modify
- Ensure output fields match Fact_AML_Alerts

## CONSTRAINTS

Do not build Power BI.
Do not change the approved data model unless absolutely necessary.
If a change is needed, explain why before implementing it.
