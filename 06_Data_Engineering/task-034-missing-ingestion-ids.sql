/*

## SQL Task 34 — Detect Missing Payment Ingestion IDs

Intermediate

SQL Server 2022 · Data Quality

File: `06_Data_Engineering/task-034-missing-ingestion-ids.sql`\
Database: `DataEngineeringPracticeDB_Lite`\
Practice table: `#PaymentIngestionAudit`

### Business requirement

A bank's Data Engineering team needs to identify missing ingestion identifiers during a daily data-quality audit.

The source contains payment ingestion records with numeric `IngestionID` values. Some identifiers are missing from the sequence.

Your task is to identify all missing integer IDs between the minimum and maximum existing ingestion IDs.

### Step 1 — Dataset setup

Execute this script in SSMS:

```
USE DataEngineeringPracticeDB_Lite;
GO

DROP TABLE IF EXISTS #PaymentIngestionAudit;

CREATE TABLE #PaymentIngestionAudit
(
    IngestionID INT PRIMARY KEY,
    PaymentID INT NOT NULL
);

INSERT INTO #PaymentIngestionAudit
    (IngestionID, PaymentID)
VALUES
    (101, 5001),
    (102, 5002),
    (104, 5003),
    (105, 5004),
    (108, 5005),
    (110, 5006);
```

Keep the same SSMS session open because the temporary table is session-scoped.

### Step 2 — Your SQL assignment

Write a query that satisfies the following requirements:

1. Find all missing `IngestionID` values between the smallest and largest existing IDs.
2. Return one row per missing ID.
3. Name the output column `MissingIngestionID`.
4. Sort the result in ascending order.
5. Do not insert, update, or delete records.

### Expected output format

| MissingIngestionID |
| ------------------ |
| ?                  |
| ?                  |
| ...                |

I will not reveal the expected values or provide SQL hints before your attempt.

### Evaluation

Your query will be assessed on correctness, completeness, SQL Server 2022 compatibility, handling of consecutive gaps, and efficiency.

Submit your SQL query first. I will then share the expected result, compare it with your logic, score your solution out of 10, and provide correction points if necessary.

*/

WITH SmallandLargestID AS
(
SELECT 
    MIN(IngestionID) SmallestID,
    MAX(IngestionID) LargestID
FROM #PaymentIngestionAudit
)
,
MissingRecordFind AS
(
SELECT
    SmallestID AS Newrecord
FROM SmallandLargestID D
UNION ALL
SELECT
    Newrecord + 1
FROM MissingRecordFind c
INNER JOIN SmallandLargestID d
ON d.LargestID > c.Newrecord
)

SELECT 
    Newrecord AS MissingIngestionID
FROM MissingRecordFind M
WHERE NOT EXISTS
    (
    SELECT 1 FROM #PaymentIngestionAudit A WHERE M.Newrecord = A.IngestionID)
    )
ORDER BY MissingIngestionID ASC
OPTION (MAXRECURSION 100)