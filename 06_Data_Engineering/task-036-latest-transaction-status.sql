/*

## SQL Task 36 — Identify the Latest Transaction Status

Intermediate

SQL Server 2022 · Window Functions · Banking Data Engineering

File: `06_Data_Engineering/task-036-latest-transaction-status.sql`\
Database: `DataEngineeringPracticeDB_Lite`\
Practice table: `#TransactionStatusHistory`

### 1. Business requirement

A bank receives multiple status updates for the same payment transaction.

For example, a transaction may initially be `Pending`, then move to `Processing`, and finally become `Success` or `Failed`.

The reconciliation team needs a dataset containing only the latest status record for each transaction.

The latest record must be determined by:

1. `StatusUpdatedAt` — most recent timestamp.
2. `StatusHistoryID` — highest ID when timestamps are identical.

### 2. Dataset setup

Execute this script in SSMS:

```
USE DataEngineeringPracticeDB_Lite;
GO

DROP TABLE IF EXISTS #TransactionStatusHistory;

CREATE TABLE #TransactionStatusHistory
(
    StatusHistoryID INT PRIMARY KEY,
    TransactionID VARCHAR(20) NOT NULL,
    AccountID VARCHAR(10) NOT NULL,
    TransactionAmount DECIMAL(18,2) NOT NULL,
    TransactionStatus VARCHAR(20) NOT NULL,
    StatusUpdatedAt DATETIME2(0) NOT NULL
);

INSERT INTO #TransactionStatusHistory
(
    StatusHistoryID,
    TransactionID,
    AccountID,
    TransactionAmount,
    TransactionStatus,
    StatusUpdatedAt
)
VALUES
(1,  'TXN101', 'A101', 5000, 'Pending',    '2026-10-25 09:00:00'),
(2,  'TXN101', 'A101', 5000, 'Processing', '2026-10-25 09:05:00'),
(3,  'TXN101', 'A101', 5000, 'Success',    '2026-10-25 09:10:00'),

(4,  'TXN102', 'A102', 3000, 'Pending',    '2026-10-25 10:00:00'),
(5,  'TXN102', 'A102', 3000, 'Failed',     '2026-10-25 10:15:00'),

(6,  'TXN103', 'A103', 7000, 'Pending',    '2026-10-25 11:00:00'),
(7,  'TXN103', 'A103', 7000, 'Processing', '2026-10-25 11:20:00'),
(8,  'TXN103', 'A103', 7000, 'Success',    '2026-10-25 11:20:00'),

(9,  'TXN104', 'A104', 2000, 'Pending',    '2026-10-25 12:00:00'),

(10, 'TXN105', 'A105', 9000, 'Pending',    '2026-10-25 13:00:00'),
(11, 'TXN105', 'A105', 9000, 'Failed',     '2026-10-25 13:10:00'),
(12, 'TXN105', 'A105', 9000, 'Success',    '2026-10-25 13:30:00');
```

### 3. Your assignment

Write a read-only SQL query that meets these acceptance criteria:

| # | Requirement                                                               |
| - | ------------------------------------------------------------------------- |
| 1 | Return exactly one latest status record per `TransactionID`               |
| 2 | Determine latest using `StatusUpdatedAt DESC`                             |
| 3 | Break timestamp ties using `StatusHistoryID DESC`                         |
| 4 | Include transactions even if their latest status is `Pending` or `Failed` |
| 5 | Do not use `DISTINCT` to remove duplicate records                         |
| 6 | Sort final output by `TransactionID ASC`                                  |

### 4. Required output columns

| Column            | Description                          |
| ----------------- | ------------------------------------ |
| TransactionID     | Unique transaction reference         |
| AccountID         | Associated bank account              |
| TransactionAmount | Payment amount                       |
| TransactionStatus | Latest recorded status               |
| StatusUpdatedAt   | Timestamp of latest update           |
| StatusHistoryID   | ID of selected status history record |

Expected result values are intentionally withheld until you submit your solution.

### 5. Evaluation criteria

I will evaluate your query for correctness, partitioning/grain, deterministic tie-breaking, filtering, ordering, and SQL Server compatibility.

Your turn: Execute the dataset setup, write your query independently, and submit your SQL with the SSMS result.

No hints or solution before your attempt. I will not assign Task 37 until you explicitly request it.

*/


WITH SuccessBatchIdentified AS
(
SELECT 
    TransactionID,
    AccountID,
    TransactionAmount,
    TransactionStatus,
    StatusUpdatedAt,
    StatusHistoryID,
    ROW_NUMBER() OVER(PARTITION BY TransactionID ORDER BY StatusUpdatedAt DESC, StatusHistoryID DESC) AS RN
FROM #TransactionStatusHistory
)

SELECT
    TransactionID,
    AccountID,
    TransactionAmount,
    TransactionStatus,
    StatusUpdatedAt,
    StatusHistoryID    
FROM SuccessBatchIdentified 
WHERE RN = 1
ORDER BY TransactionID ASC

/*

## Task 36 — Final SQL Review ✅

Final score

# 10/10

Status

Logic passed

Your revised SQL now satisfies all six output requirements. The missing `StatusUpdatedAt` column has been included, and your window function correctly selects the latest record for each transaction.

### 1. Technical assessment

| Evaluation criteria                | Result |
| ---------------------------------- | ------ |
| Correct CTE structure              | Pass   |
| `ROW_NUMBER()` implementation      | Pass   |
| `PARTITION BY TransactionID`       | Pass   |
| `StatusUpdatedAt DESC`             | Pass   |
| `StatusHistoryID DESC` tie-breaker | Pass   |
| `WHERE RN = 1`                     | Pass   |
| All six required columns           | Pass   |
| Final ascending sort               | Pass   |

### 2. Expected SQL result

| TransactionID | AccountID | TransactionAmount | TransactionStatus | StatusUpdatedAt     | StatusHistoryID |
| ------------- | --------- | ----------------- | ----------------- | ------------------- | --------------- |
| TXN101        | A101      | 5000.00           | Success           | 2026-10-25 09:10:00 | 3               |
| TXN102        | A102      | 3000.00           | Failed            | 2026-10-25 10:15:00 | 5               |
| TXN103        | A103      | 7000.00           | Success           | 2026-10-25 11:20:00 | 8               |
| TXN104        | A104      | 2000.00           | Pending           | 2026-10-25 12:00:00 | 9               |
| TXN105        | A105      | 9000.00           | Success           | 2026-10-25 13:30:00 | 12              |

Expected 5 rows based on the supplied dataset. Actual SSMS output has not been provided.

### 3. Learning log

Your progression across the three attempts:

| Attempt | Score | Main finding                                 |
| ------- | ----- | -------------------------------------------- |
| 1       | 3/10  | Incorrect CASE logic and use of `MAX()`      |
| 2       | 9/10  | Correct row selection; missing output column |
| 3       | 10/10 | All acceptance criteria satisfied            |

Concept mastered: Using `ROW_NUMBER()` with deterministic ordering to select the latest record within each business-key partition.

This pattern is directly applicable to CDC pipelines, payment status history, deduplication, and latest-state data models.

### 4. Git checkpoint

File: `06_Data_Engineering/task-036-latest-transaction-status.sql`

After saving and executing the query in SSMS:

```
git add 06_Data_Engineering/task-036-latest-transaction-status.sql
git commit -m "Complete Task 36 latest transaction status using ROW_NUMBER"
git push
```

Task 36: SQL logic completed — 10/10. No further code corrections are required. I will wait for your explicit request before assigning Task 37.

*/