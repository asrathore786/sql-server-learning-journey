/*

# Task 040 — Duplicate Payment Detection

## 1. Business Requirement

The Payments Operations team wants to identify potentially duplicated payment records in the payment system. Duplicate records may indicate accidental duplicate processing, repeated data ingestion, or other data-quality issues.

Write a SQL Server query against `dbo.Payments` to identify duplicate payment groups.

Two or more records belong to the same duplicate group when they have identical values across all five columns:

- `OrderID`
- `PaymentDate`
- `PaymentMethod`
- `PaymentStatus`
- `PaymentAmount`

## 2. Expected Output

Return exactly the following seven columns:

| Column | Description |
|---|---|
| `OrderID` | Order associated with the payment |
| `PaymentDate` | Payment transaction date |
| `PaymentMethod` | Method used for payment |
| `PaymentStatus` | Current payment status |
| `PaymentAmount` | Amount recorded for the payment |
| `DuplicateCount` | Total number of records in the duplicate group |
| `DuplicateExcessCount` | Number of records beyond the first record in the group |

## 3. Business Rules

1. Identify duplicate groups using all five specified columns.
2. Return only groups containing more than one record.
3. `DuplicateCount` must represent the total number of records in the group.
4. `DuplicateExcessCount` must represent the number of records beyond the first record.
5. Sort the results by `DuplicateCount` in descending order, then `OrderID` in ascending order.
6. This is a read-only detection task. Do not delete, update, or modify any records.
7. If no duplicate groups exist, the query should return zero rows.

## 4. Technical Constraints

- Use SQL Server syntax compatible with SQL Server 2022.
- Use the existing `DataEngineeringPracticeDB` database.
- Query only the existing `dbo.Payments` table.
- Do not create or modify tables, views, or other database objects.
- Save your solution in this file: `task-040-duplicate-payment-detection.sql`

## 5. Acceptance Criteria

The query is correct only if it:
- Identifies duplicate groups using the complete five-column definition.
- Returns exactly seven columns with the specified meanings.
- Calculates both duplicate counts correctly.
- Excludes groups containing only one record.
- Applies the required sorting.
- Does not modify the source data.

*/

WITH RANK_Duplicate AS
(
SELECT
	OrderID,
	PaymentMethod,
	PaymentStatus,
	PaymentAmount,
	PaymentDate,
	COUNT(*) DuplicateCount
FROM Payments
GROUP BY 
	OrderID,PaymentMethod,PaymentStatus,PaymentAmount,PaymentDate
HAVING COUNT(*) > 1
)

SELECT 
	OrderID,
	PaymentDate,
	PaymentMethod,
	PaymentStatus,
	PaymentAmount,
	DuplicateCount,
	DuplicateCount - 1 AS DuplicateExcessCount
FROM RANK_Duplicate
ORDER BY 
	DuplicateCount DESC,
	OrderID ASC
/*

✅ Task 040 — Duplicate Payment Detection: Completed and validated.

Your query returned the expected three duplicate groups after inserting the test data. The original zero-row result was valid because your dataset had no matching duplicate groups before the test data was added.

## 1. Final SQL query

Filename: `task-040-duplicate-payment-detection.sql`

Folder: `06_Data_Engineering`

```

USE DataEngineeringPracticeDB;
GO

WITH DuplicateGroups AS
(
    SELECT
        OrderID,
        PaymentDate,
        PaymentMethod,
        PaymentStatus,
        PaymentAmount,
        COUNT(*) AS DuplicateCount
    FROM dbo.Payments
    GROUP BY
        OrderID,
        PaymentDate,
        PaymentMethod,
        PaymentStatus,
        PaymentAmount
)
SELECT
    OrderID,
    PaymentDate,
    PaymentMethod,
    PaymentStatus,
    PaymentAmount,
    DuplicateCount,
    DuplicateCount - 1 AS DuplicateExcessCount
FROM DuplicateGroups
WHERE DuplicateCount > 1
ORDER BY
    DuplicateCount DESC,
    OrderID ASC;

```

## 2. Task record

## Task 040

Validated

Pattern: Duplicate detection and aggregation

Concepts demonstrated

- `GROUP BY` — defines a duplicate group using all five columns.
- `COUNT(*)` — counts records within each group.
- `WHERE DuplicateCount > 1` — filters groups in the outer query after the CTE has calculated the count.
- `DuplicateCount - 1` — calculates excess duplicate records.
- `ORDER BY` — sorts the largest duplicate groups first.
- CTEs — separate aggregation from final filtering and presentation.

  Mistakes corrected

1. Removed unnecessary `RANK()`.
2. Added the duplicate-group filter.
3. Changed sorting from ascending to descending duplicate count.
4. Corrected the output column order.
5. Used existing `OrderID` values to satisfy the foreign key constraint when inserting test records.

## 3. Validation results

| OrderID | DuplicateCount | DuplicateExcessCount |
| ------- | -------------- | -------------------- |
| 10003   | 4              | 3                    |
| 10001   | 3              | 2                    |
| 10002   | 2              | 1                    |

All three groups match the expected counts and ordering. Order `10004` is correctly excluded because its test record appears only once.

## 4. Important learning point

You initially received zero rows, but your query was not necessarily wrong. The absence of matching data and an incorrect query are two different problems. You diagnosed the data issue and inserted controlled test records, which is an important SQL debugging skill.

One caution: the inserted records are deliberately duplicated test data. Keep them clearly documented in your practice database so they do not distort future payment-analysis exercises.

## 5. Git commands

After saving the final query in the correct file, run these commands from your repository folder:

```
git add 06_Data_Engineering/task-040-duplicate-payment-detection.sql
git commit -m "Add task 040 duplicate payment detection"
git push origin main
```

These commands assume the file has been saved and your Git remote is configured.

Next: Task 041 should move to another practical SQL pattern. I recommend Self Joins, where you compare rows within the same table to identify relationships or exceptions.

*/