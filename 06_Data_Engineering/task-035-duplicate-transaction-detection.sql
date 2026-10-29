/*

## SQL Task 35 — Duplicate Banking Transaction Detection

Intermediate

SQL Server 2022 · Data Quality · Banking Reconciliation

File: `06_Data_Engineering/task-035-duplicate-transaction-detection.sql`\
Database: `DataEngineeringPracticeDB_Lite`\
Practice table: `#BankTransactions`

### 1. Business requirement

During daily reconciliation, the banking operations team identifies a potential issue: some transactions may have been ingested multiple times.

As a Data Engineer, you must identify duplicate transaction groups before the records are processed downstream.

A transaction is considered a duplicate when these three fields match:

`AccountID + TransactionReference + TransactionAmount`

Important: `TransactionDate` is not part of the duplicate identification key.

### 2. Dataset setup

Execute the following script in SSMS.

```
USE DataEngineeringPracticeDB_Lite;
GO

DROP TABLE IF EXISTS #BankTransactions;

CREATE TABLE #BankTransactions
(
    RecordID INT PRIMARY KEY,
    AccountID VARCHAR(10),
    TransactionReference VARCHAR(20),
    TransactionAmount DECIMAL(18,2),
    TransactionDate DATE
);

INSERT INTO #BankTransactions
(
    RecordID,
    AccountID,
    TransactionReference,
    TransactionAmount,
    TransactionDate
)
VALUES
(1, 'A101', 'TXN001', 5000, '2026-10-01'),
(2, 'A101', 'TXN001', 5000, '2026-10-01'),
(3, 'A102', 'TXN002', 3000, '2026-10-02'),
(4, 'A103', 'TXN003', 7000, '2026-10-03'),
(5, 'A103', 'TXN003', 7000, '2026-10-03'),
(6, 'A103', 'TXN003', 7000, '2026-10-03'),
(7, 'A104', 'TXN004', 2000, '2026-10-04'),
(8, 'A101', 'TXN001', 6000, '2026-10-05'),
(9, 'A105', 'TXN005', 9000, '2026-10-06'),
(10, 'A105', 'TXN005', 9000, '2026-10-07');
```

Keep the same SSMS connection open when querying the local temporary table.

### 3. Your assignment

Write a read-only SQL query that meets the following acceptance criteria:

| # | Requirement                                         |
| - | --------------------------------------------------- |
| 1 | Identify duplicate transaction groups               |
| 2 | Use the defined three-column business key           |
| 3 | Return `AccountID`                                  |
| 4 | Return `TransactionReference`                       |
| 5 | Return `TransactionAmount`                          |
| 6 | Return `DuplicateCount`                             |
| 7 | Exclude transaction groups that occur only once     |
| 8 | Sort by `DuplicateCount DESC`, then `AccountID ASC` |

### 4. Expected output structure

Column structure only — expected rows and values are intentionally withheld.

| AccountID | TransactionReference | TransactionAmount | DuplicateCount |
| --------- | -------------------- | ----------------- | -------------- |
| ...       | ...                  | ...               | ...            |

### 5. Evaluation criteria

Your submission will be assessed on business-key accuracy, SQL correctness, grouping granularity, duplicate detection, sorting, and efficiency.

Your turn: Submit your SQL query first. I will then review it, share the expected result, assign a score out of 10, and record any correction points.

No solution or hints before your attempt.

*/

SELECT 
    AccountID,
    TransactionReference,
    TransactionAmount,
    COUNT(*) AS DuplicateCount
FROM #BankTransactions
GROUP BY 
    AccountID,
    TransactionReference,
    TransactionAmount
HAVING COUNT(*) > 1
ORDER BY 
    DuplicateCount DESC,
    AccountID ASC

/*

## Task 35 — SQL Code Review

SQL score

# 10/10

Assessment

Passed

Your SQL query is fully correct for the provided dataset and business requirements. You identified the correct transaction grain, applied aggregation, filtered duplicate groups, and sorted the output correctly.

### 1. Technical review

| Evaluation criteria                   | Result     |
| ------------------------------------- | ---------- |
| Correct business key (3 columns)      | &#x20;Pass |
| Correct `GROUP BY`                    | &#x20;Pass |
| Correct `HAVING` condition            | &#x20;Pass |
| Correct duplicate count               | &#x20;Pass |
| Excludes unique transactions          | &#x20;Pass |
| Ignores `TransactionDate` as required | &#x20;Pass |
| Correct sorting                       | &#x20;Pass |
| SQL Server compatibility              | &#x20;Pass |

### 2. Expected SQL output

Based on the supplied Task 35 dataset:

| AccountID | TransactionReference | TransactionAmount | DuplicateCount |
| --------- | -------------------- | ----------------- | -------------- |
| A103      | TXN003               | 7000.00           | 3              |
| A101      | TXN001               | 5000.00           | 2              |
| A105      | TXN005               | 9000.00           | 2              |

Expected: 3 rows. This output is derived from the setup data, not an independently executed SSMS result.

### 3. Detailed assessment

Your query correctly uses:

```
GROUP BY
    AccountID,
    TransactionReference,
    TransactionAmount
HAVING COUNT(AccountID) > 1
```

This is the correct aggregation grain.

You also correctly excluded `TransactionDate` from `GROUP BY`, allowing records with different transaction dates to be classified as duplicates when their three-column business keys match.

One production consideration: `COUNT(AccountID)` counts only non-NULL account IDs. Since the table definition permits NULLs, `COUNT(*)` is generally more robust for counting all records within each group. This does not affect your result because all sample account IDs are populated.

### 4. Correction points / learning log

| Area                     | Finding                                         |
| ------------------------ | ----------------------------------------------- |
| `GROUP BY`               | Correct grouping grain                          |
| `HAVING` vs `WHERE`      | Correct use of `HAVING` for aggregate filtering |
| Duplicate identification | Correct                                         |
| NULL handling            | Prefer `COUNT(*)` for production row counts     |
| Recurring mistakes       | None identified in this submission              |

### 5. Git checkpoint

File: `06_Data_Engineering/task-035-duplicate-transaction-detection.sql`

After saving and verifying the query in SSMS:

```
git add 06_Data_Engineering/task-035-duplicate-transaction-detection.sql
git commit -m "Complete duplicate banking transaction detection"
git push
```

Task 35 status: SQL logic passed (10/10). SSMS output verification remains optional if you want to confirm the three expected rows.

I will not issue Task 36 until you explicitly request it.

*/