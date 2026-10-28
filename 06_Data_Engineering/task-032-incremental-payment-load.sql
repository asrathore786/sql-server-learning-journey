/*

## Task 32 — Incremental ETL Processing Using Watermarks

Intermediate–Advanced

SQL Server 2022

File: `task-032-incremental-payment-load.sql`\
Folder: `06_Data_Engineering/`\
Database: `DataEngineeringPracticeDB_Lite`\
Source table: `banking.PaymentIngestion`

### 1. Business scenario

You are a Data Engineer working on a bank's payment-processing pipeline.

The payment gateway continuously sends records into `banking.PaymentIngestion`. The ETL pipeline runs periodically, and the bank wants to process only records that arrived after the previous successful ETL run.

Reprocessing the entire ingestion table every time is inefficient.

Your task is to implement the extraction logic for an incremental ETL load using a watermark.

### 2. Watermark configuration

Assume the previous successful ETL run processed records through:

Last successful ingestion watermark

## 2026-10-28 12:00:00

Only records ingested strictly after this timestamp qualify for the next extraction.

### 3. Test data

We will continue using the shared dataset. No new tables are required.

Execute this verification query in SSMS:

```
USE DataEngineeringPracticeDB_Lite;
GO

SELECT
    IngestionID,
    PaymentID,
    CustomerID,
    PaymentAmount,
    PaymentStatus,
    IngestionTime
FROM banking.PaymentIngestion
ORDER BY IngestionTime, IngestionID;
```

The existing dataset contains 13 ingestion records.

### 4. Expected output — Part A

Your incremental extraction must return these five records:

| IngestionID | PaymentID | CustomerID | PaymentStatus | IngestionTime    |
| ----------- | --------- | ---------- | ------------- | ---------------- |
| 9           | 205       | C3         | Success       | 2026-10-28 13:00 |
| 10          | 205       | C3         | Failed        | 2026-10-28 13:30 |
| 11          | 206       | C4         | Pending       | 2026-10-28 14:00 |
| 12          | 206       | C4         | Success       | 2026-10-28 14:00 |
| 13          | 207       | C6         | Pending       | 2026-10-28 15:00 |

PaymentAmount must also appear in your actual SQL output; it is omitted from this display for readability.

Notice that two records have the same `IngestionTime`. Both must be extracted.

### 5. Business rules

1. Use `banking.PaymentIngestion` as the source.
2. Declare the previous successful watermark as a T-SQL variable.
3. Return only records ingested strictly after that watermark.
4. Do not filter by payment status.
5. Do not deduplicate payments during extraction.
6. Return all six source columns.
7. Sort by `IngestionTime` ascending, then `IngestionID` ascending.
8. Do not modify or delete any records.

### 6. Evaluation criteria

| Area                  | Assessment                                |
| --------------------- | ----------------------------------------- |
| Watermark variable    | Correct declaration and datatype          |
| Incremental filtering | Correct comparison against watermark      |
| Data completeness     | All qualifying ingestion records retained |
| Duplicate handling    | No unintended deduplication               |
| Ordering              | Deterministic extraction sequence         |
| T-SQL                 | Valid SQL Server syntax                   |

### Your assignment — Task 32A

Write a complete T-SQL query that extracts the five qualifying ingestion records.

Use the existing shared table. No setup script or additional INSERT statements are needed.

Submit your SQL and actual SSMS output. I will review them before moving to Part B, where we will address watermark advancement and late-arriving records.

No hints or solution before your attempt.

*/

/*

Correct. ✅ Score: 10/10

You selected B — Insert only IngestionID 14.

The target already contains ingestion records 11 and 12. Inserting them again would create duplicates.

| IngestionID | Already in target? | Action |
| ----------- | ------------------ | ------ |
| 11          | Yes                | Skip   |
| 12          | Yes                | Skip   |
| 14          | No                 | Insert |

This demonstrates idempotent loading: processing the same source records repeatedly does not create additional copies.

## Task 32C — Practical SQL: Idempotent Incremental Loading

FILE

&#x20;Copy path

`06_Data_Engineering/task-032-idempotent-payment-load.sql`

Database: `DataEngineeringPracticeDB_Lite`

### Business requirement

Your ETL pipeline must identify ingestion records that have not yet been loaded into the raw target.

For this exercise, assume:

- Source: `banking.PaymentIngestion`
- Target: `banking.PaymentIngestionTarget`
- Unique ingestion identifier: `IngestionID`
- The target already contains ingestion IDs 11 and 12.
- The incoming batch contains ingestion IDs 11, 12 and 14.

Your task: Write a SQL Server `SELECT` query using `NOT EXISTS` that returns only source records whose `IngestionID` does not exist in the target.

Expected output:

| IngestionID |
| ----------- |
| 14          |

### Requirements

1. Use `NOT EXISTS` with a correlated subquery.
2. Compare source and target using `IngestionID`, not `PaymentID`.
3. Return all six source columns.
4. Do not filter on `PaymentStatus`.
5. Do not insert or modify records yet.

Important: `banking.PaymentIngestionTarget` is a proposed practice target, not a confirmed existing table. Do not run the query against it until we establish the target schema and test data.

### Your first question

Before writing SQL, explain this:

Why should the `NOT EXISTS` condition compare `IngestionID` instead of `PaymentID`?

Answer in your own words. We'll validate your understanding before implementing the query.
*/




INSERT INTO banking.PaymentIngestionTarget (
    IngestionID,
    PaymentID,
    CustomerID,
    PaymentAmount,
    PaymentStatus,
    IngestionTime )
FROM
SELECT
    IngestionID,
    PaymentID,
    CustomerID,
    PaymentAmount,
    PaymentStatus,
    IngestionTime
FROM banking.PaymentIngestion P
WHERE NOT EXISTS
(SELECT 1 FROM Banking.PaymentIngestionTarget T WHERE P.IngestionID = T.IngestionID)
