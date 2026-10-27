/*

Good. We'll now use the shared banking dataset for Task 31 and future SQL exercises.

## Task 31 — Payment Deduplication & Data Quality

File: `task-031-payment-deduplication.sql`\
Folder: `06_Data_Engineering/`\
Database: `DataEngineeringPracticeDB_Lite`

Tables:

- `banking.Customers`
- `banking.PaymentIngestion`

### Part A — Customer reconciliation

Write a SQL query that identifies the latest ingested record for each `PaymentID` and calculates successful payment counts and amounts per customer.

Expected output:

| CustomerID | CustomerName | SuccessfulPaymentCount | SuccessfulPaymentAmount |
| ---------- | ------------ | ---------------------- | ----------------------- |
| C1         | Amit         | 1                      | 5,000.00                |
| C2         | Neha         | 2                      | 9,000.00                |
| C3         | Rahul        | 0                      | 0.00                    |
| C4         | Priya        | 1                      | 6,000.00                |
| C5         | Vikram       | 0                      | 0.00                    |
| C6         | Simran       | 0                      | 0.00                    |

### Part B — Duplicate ingestion detection

Write a second query to identify `PaymentID` values ingested multiple times.

Expected output:

| PaymentID | IngestionRecordCount |
| --------- | -------------------- |
| 201       | 3                    |
| 202       | 2                    |
| 203       | 2                    |
| 205       | 2                    |
| 206       | 2                    |

Requirements: Use the latest `IngestionTime`, break timestamp ties using the highest `IngestionID`, preserve all customers, and avoid double-counting payments.

Submit Part A first. I'll review it before we proceed to Part B.

No hints or solutions before your attempt.

*/

WITH PaymentSuccess AS
(
SELECT 
	a. CustomerID,
	a.PaymentAmount
FROM 
(
SELECT
	PaymentID,
	CustomerID,
	PaymentAmount,
	PaymentStatus,
	IngestionTime,
	ROW_NUMBER() OVER(PARTITION BY PaymentID ORDER BY IngestionTime DESC,IngestionID DESC) AS RNK
FROM banking.PaymentIngestion
) a
WHERE PaymentStatus = 'Success'
AND RNK = 1 
)

SELECT 
	C.CustomerID,
	C.CustomerName,
	COUNT(P.CustomerID) AS SuccessfulPaymentCount,
	COALESCE(SUM(P.PaymentAmount),0) AS SuccessfulPayment
FROM banking.Customers C
LEFT JOIN PaymentSuccess P
ON C.CustomerID = P.CustomerID
GROUP BY 
	C.CustomerID,
	C.CustomerName
ORDER BY 
	C.CustomerID 

/*

## Task 31 — Part A: Final SQL Review

Final score

# 10/10

SQL syntax

Valid

Assessment

Passed

Your revised query now correctly implements the complete business requirement. You fixed the deduplication key by changing:

`PARTITION BY CustomerID, PaymentID`

to:

`PARTITION BY PaymentID`

This ensures that only the latest ingested version of each payment is selected, even if its `CustomerID` changes between ingestion records.

### 1. Expected output

| CustomerID | CustomerName | SuccessfulPaymentCount | SuccessfulPayment |
| ---------- | ------------ | ---------------------- | ----------------- |
| C1         | Amit         | 1                      | 5,000.00          |
| C2         | Neha         | 2                      | 9,000.00          |
| C3         | Rahul        | 0                      | 0.00              |
| C4         | Priya        | 1                      | 6,000.00          |
| C5         | Vikram       | 0                      | 0.00              |
| C6         | Simran       | 0                      | 0.00              |

This is the expected output from the original shared dataset, assuming it has not been modified.

### 2. Technical review

| Criteria                                   | Result        |
| ------------------------------------------ | ------------- |
| Deduplication by `PaymentID`               | &#x20;Correct |
| Latest `IngestionTime` selection           | &#x20;Correct |
| `IngestionID` tie-breaker                  | &#x20;Correct |
| Filter `Success` after deduplication       | &#x20;Correct |
| `LEFT JOIN` preserves all customers        | &#x20;Correct |
| `COUNT(P.CustomerID)` handles zero matches | &#x20;Correct |
| `COALESCE(SUM(...), 0)`                    | &#x20;Correct |
| Customer-level grouping                    | &#x20;Correct |
| Output sorting                             | &#x20;Correct |

### 3. Learning log

Your progression through Task 31 Part A:

| Attempt | Score | Main issue                                     |
| ------- | ----- | ---------------------------------------------- |
| First   | 7/10  | Counted customers instead of matching payments |
| Second  | 9/10  | Deduplicated by customer-payment combination   |
| Third   | 10/10 | Both issues corrected                          |

You have now demonstrated correct handling of deduplication grain, latest-record selection, and zero-payment customers.

Actual SSMS execution remains unverified.

## Task 31 — Part B: Duplicate Ingestion Detection

File: `06_Data_Engineering/task-031-payment-deduplication.sql`

Database: `DataEngineeringPracticeDB_Lite`

Table: `banking.PaymentIngestion`

### Business requirement

Identify all `PaymentID` values that appear more than once in the ingestion table.

Expected output:

| PaymentID | IngestionRecordCount |
| --------- | -------------------- |
| 201       | 3                    |
| 202       | 2                    |
| 203       | 2                    |
| 205       | 2                    |
| 206       | 2                    |

Your task: Write a SQL query returning exactly these two columns, sorted by `PaymentID`.

Do not hardcode payment IDs or counts.

Submit your SQL for review. No hints or solution before your attempt.

*/

SELECT 
	PaymentID,
	COUNT(PaymentID) AS IngestionRecordCount
FROM banking.PaymentIngestion
GROUP BY PaymentID
HAVING COUNT(PaymentID) > 1
ORDER BY PaymentID

/*

## Task 31 — Final Review: Completed ✅

Final score

# 10/10

SQL execution

Passed

Output

Exact match

Your revised query is correct, and the SSMS output you provided matches all five expected records.

### Final validation

| Evaluation                    | Result      |
| ----------------------------- | ----------- |
| `GROUP BY PaymentID`          | Correct     |
| `COUNT(PaymentID)`            | Correct     |
| `HAVING COUNT(PaymentID) > 1` | Correct     |
| `ORDER BY PaymentID`          | Correct     |
| Expected record count         | 5           |
| Actual record count           | 5           |
| Expected vs. actual values    | Exact match |

### Task 31 — Overall results

| Section                                           | Final score | Status    |
| ------------------------------------------------- | ----------- | --------- |
| Part A — Payment deduplication and reconciliation | 10/10       | Passed    |
| Part B — Duplicate ingestion detection            | 10/10       | Passed    |
| Overall                                           | 10/10       | Completed |

### Save and commit to Git

File: `06_Data_Engineering/task-031-payment-deduplication.sql`\
Database: `DataEngineeringPracticeDB_Lite`

Save both Part A and Part B in the same file.

Run from your Git repository root:

```
git status
git add 06_Data_Engineering/task-031-payment-deduplication.sql
git commit -m "Task 31: Payment deduplication and data quality validation"
git push
```

### Learning log

Skills demonstrated: Window-function deduplication, deterministic ordering, `LEFT JOIN`, zero-count handling, financial aggregation, `GROUP BY`, `HAVING`, and result ordering.

Correction pattern: You independently resolved the incorrect `COUNT()` expression, corrected the deduplication partition key, and added the missing `ORDER BY`.

Next task: Q32 — Incremental ETL Processing Using Watermarks.

We will continue using your existing `DataEngineeringPracticeDB_Lite` banking dataset rather than creating new task-specific tables.

*/