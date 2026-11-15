/*

## **SQL Practice — Task 45**

Task 45

SQL Server 2022

Data Engineering

**Database:** `DataEngineeringPracticeDB_Lite`

**Save file:** `06_Data_Engineering/task-045-banking-transaction-anomaly-detection.sql`

### **1. Business requirement**

A bank's fraud-monitoring team wants to identify unusually large debit transactions.

For each account, the bank calculates the average amount of its previous three debit transactions. A new debit transaction is considered suspicious when its amount is **strictly greater than twice that historical average**.

Your task is to produce a transaction-level anomaly report.

Business rules:

1. Consider only `DEBIT` transactions.
2. Evaluate each account independently.
3. Calculate the average amount of the **previous three debit transactions**, excluding the current transaction.
4. Process transactions by `TransactionDate` ascending, then `TransactionID` ascending.
5. A transaction must have three previous debit transactions before it is eligible for evaluation.
6. Flag a transaction only when `Amount > 2 × Previous3Avg`.
7. Do not flag transactions equal to the threshold.
8. Return only suspicious transactions.

This is a historical transaction-based rule, not a calendar-day-based rule.

### **2. Dataset — Execute in SSMS**

```

USE DataEngineeringPracticeDB_Lite;
GO

DROP TABLE IF EXISTS #FraudTransactions;

CREATE TABLE #FraudTransactions (
    TransactionID INT PRIMARY KEY,
    AccountID INT NOT NULL,
    TransactionDate DATETIME2(0) NOT NULL,
    TransactionType VARCHAR(10) NOT NULL,
    Amount DECIMAL(14,2) NOT NULL
);

INSERT INTO #FraudTransactions VALUES
-- Account 1001
(101,1001,'2026-11-01 09:00:00','DEBIT',1000),
(102,1001,'2026-11-02 09:00:00','DEBIT',1200),
(103,1001,'2026-11-03 09:00:00','DEBIT',800),
(104,1001,'2026-11-04 09:00:00','DEBIT',3000),
(105,1001,'2026-11-05 09:00:00','DEBIT',1500),
(106,1001,'2026-11-06 09:00:00','CREDIT',9000),
(107,1001,'2026-11-07 09:00:00','DEBIT',5000),

-- Account 1002
(201,1002,'2026-11-01 10:00:00','DEBIT',2000),
(202,1002,'2026-11-02 10:00:00','DEBIT',2200),
(203,1002,'2026-11-03 10:00:00','DEBIT',1800),
(204,1002,'2026-11-04 10:00:00','DEBIT',4000),
(205,1002,'2026-11-05 10:00:00','DEBIT',4500),
(206,1002,'2026-11-06 10:00:00','DEBIT',9000),

-- Account 1003
(301,1003,'2026-11-01 11:00:00','DEBIT',500),
(302,1003,'2026-11-02 11:00:00','DEBIT',600),
(303,1003,'2026-11-03 11:00:00','DEBIT',700),
(304,1003,'2026-11-04 11:00:00','DEBIT',1200),
(305,1003,'2026-11-05 11:00:00','DEBIT',2500),

-- Account 1004
(401,1004,'2026-11-01 12:00:00','DEBIT',1000),
(402,1004,'2026-11-02 12:00:00','DEBIT',1000),
(403,1004,'2026-11-03 12:00:00','DEBIT',1000),
(404,1004,'2026-11-04 12:00:00','DEBIT',2000),
(405,1004,'2026-11-05 12:00:00','DEBIT',3000),

-- Account 1005
(501,1005,'2026-11-01 13:00:00','DEBIT',1000),
(502,1005,'2026-11-02 13:00:00','DEBIT',5000);

```

### **3. Required output**

Return the following columns, in this exact order:

`AccountID`, `TransactionID`, `TransactionDate`, `Amount`, `Previous3Avg`, `ThresholdAmount`, `AnomalyStatus`.

The `AnomalyStatus` value must be `SUSPICIOUS`.

Round `Previous3Avg` and `ThresholdAmount` to two decimal places.

Sort by `AccountID` ascending, then `TransactionDate` ascending, then `TransactionID` ascending.

### **4. Expected output**

Exactly 4 suspicious transactions.

| AccountID | TransactionID | TransactionDate     | Amount  | Previous3Avg | ThresholdAmount | AnomalyStatus |
| --------- | ------------- | ------------------- | ------- | ------------ | --------------- | ------------- |
| 1001      | 104           | 2026-11-04 09:00:00 | 3000.00 | 1000.00      | 2000.00         | SUSPICIOUS    |
| 1001      | 107           | 2026-11-07 09:00:00 | 5000.00 | 1766.67      | 3533.33         | SUSPICIOUS    |
| 1002      | 206           | 2026-11-06 10:00:00 | 9000.00 | 3433.33      | 6866.67         | SUSPICIOUS    |
| 1003      | 305           | 2026-11-05 11:00:00 | 2500.00 | 833.33       | 1666.67         | SUSPICIOUS    |

### **5. Acceptance criteria**

Your solution must satisfy all of the following:

- Exactly four suspicious transactions.
- Only debit transactions participate in the historical calculation.
- The current transaction is excluded from its own historical average.
- The historical window contains no more than three previous debit transactions.
- Accounts with fewer than three earlier debits are not evaluated.
- Transaction 204 for Account 1002 is excluded because its amount equals, rather than exceeds, the threshold.
- Transaction 404 for Account 1004 is excluded for the same reason.
- Account 1005 has no flagged transactions because it has insufficient history.
- Output values and sorting match the expected results.

### **6. Submission**

Write your query independently and submit both the SQL and SSMS output.

I will assess your solution out of 10, including window boundaries, account partitioning, historical eligibility, numeric precision, and output accuracy.

**No hints or solution before your attempt.** After successful validation, I will provide your correction points, learning log, and Git commands.


*/

-- `AccountID`, `TransactionID`, `TransactionDate`, `Amount`, `Previous3Avg`, `ThresholdAmount`, `AnomalyStatus`.

WITH Averagefind AS
(
SELECT
    AccountID,
    TransactionID,
    TransactionDate,
    Amount,
    ROW_NUMBER() OVER (PARTITION BY AccountID ORDER BY TransactionDate, TransactionID) AS DebitSequence,
    AVG(AMOUNT) OVER(PARTITION BY AccountID ORDER BY TransactionDate ASC, TransactionID ASC ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Previous3Avg
FROM #FraudTransactions T
WHERE T.TransactionType = 'DEBIT'
),
UsingLagForPrev AS
(
SELECT
    AccountID,
    TransactionID,
    TransactionDate,
    Amount,
    Previous3Avg,
    DebitSequence,
    LAG(Previous3Avg) OVER(PARTITION BY AccountID ORDER BY TransactionDate ASC, TransactionID ASC) AS PreviousAverage
FROM Averagefind
),
FinalDetails AS
(
SELECT
    AccountID,
    TransactionID,
    TransactionDate,
    Amount,
    DebitSequence,
    CAST(PreviousAverage AS DECIMAL(10,2)) AS Previous3Avg,
    CAST(2 * PreviousAverage AS DECIMAL(10,2)) AS ThresholdAmount,
    CASE
        WHEN Amount > 2 * PreviousAverage THEN 'SUSPICIOUS'
    END AS AnomalyStatus
FROM UsingLagForPrev
)
SELECT * FROM FinalDetails
WHERE DebitSequence >= 4 AND AnomalyStatus IS NOT NULL
ORDER BY
    AccountID,
    TransactionDate,
    TransactionID

--| AccountID | TransactionID | TransactionDate     | Amount  | Previous3Avg | ThresholdAmount | AnomalyStatus |
--| --------- | ------------- | ------------------- | ------- | ------------ | --------------- | ------------- |
--| 1001      | 104           | 2026-11-04 09:00:00 | 3000.00 | 1000.00      | 2000.00         | SUSPICIOUS    |
--| 1001      | 107           | 2026-11-07 09:00:00 | 5000.00 | 1766.67      | 3533.33         | SUSPICIOUS    |
--| 1002      | 206           | 2026-11-06 10:00:00 | 9000.00 | 3433.33      | 6866.67         | SUSPICIOUS    |
--| 1003      | 305           | 2026-11-05 11:00:00 | 2500.00 | 833.33       | 1666.67         | SUSPICIOUS    |

/*

## **Task 45 — Final SQL Review: Attempt 3**

SQL logic score

# **10/10**

Status

Logic validated

Your third attempt correctly addresses the previous issues. **The SQL logic now satisfies all Task 45 business requirements.**

### **1. Technical review**

| Requirement                           | Result |
| ------------------------------------- | ------ |
| Only debit transactions considered    | Pass   |
| Independent calculation per account   | Pass   |
| Previous three debit amounts averaged | Pass   |
| Current transaction excluded          | Pass   |
| Three previous debits required        | Pass   |
| Transaction timestamp tie-breaker     | Pass   |
| Strictly greater-than threshold       | Pass   |
| Two-decimal precision                 | Pass   |
| Correct final ordering                | Pass   |

### **2. Why your solution works**

Your `Averagefind` CTE uses:

```
ROW_NUMBER() OVER (
    PARTITION BY AccountID
    ORDER BY TransactionDate, TransactionID
) AS DebitSequence
```

This assigns a sequence number to each debit within its account.

Your `AVG()` calculates a rolling average including the current transaction, and `LAG()` shifts that result forward by one transaction. Together, they produce the average of the previous three debits.

Finally:

```
WHERE DebitSequence >= 4
  AND AnomalyStatus IS NOT NULL
```

ensures that only eligible, suspicious transactions appear.

This is a correct combination of window functions.

### **3. Corrected expected output**

Your query should return **five suspicious transactions**, including TransactionID `405`, which you correctly identified earlier.

| AccountID | TransactionID | Amount   | Previous3Avg | ThresholdAmount |
| --------- | ------------- | -------- | ------------ | --------------- |
| 1001      | 104           | 3,000.00 | 1,000.00     | 2,000.00        |
| 1001      | 107           | 5,000.00 | 1,766.67     | 3,533.33        |
| 1002      | 206           | 9,000.00 | 3,433.33     | 6,866.67        |
| 1003      | 305           | 2,500.00 | 833.33       | 1,666.67        |
| 1004      | 405           | 3,000.00 | 1,333.33     | 2,666.67        |

All five rows should have `AnomalyStatus = 'SUSPICIOUS'`.

### **4. One minor output correction**

Your final statement uses:

```
SELECT * FROM FinalDetails
```

This includes `DebitSequence`, which is an internal calculation column and was not requested in the final report.

For exact compliance, explicitly select the seven required columns:

```
SELECT
    AccountID,
    TransactionID,
    TransactionDate,
    Amount,
    Previous3Avg,
    ThresholdAmount,
    AnomalyStatus
FROM FinalDetails
WHERE DebitSequence >= 4
  AND AnomalyStatus IS NOT NULL
ORDER BY
    AccountID,
    TransactionDate,
    TransactionID;
```

This does not change your underlying calculations.

### **5. Correction points / learning log**

| Attempt | Main issue                                        | Progress    |
| ------- | ------------------------------------------------- | ----------- |
| 1       | Incorrect threshold and missing eligibility check | 7/10        |
| 2       | Threshold fixed; eligibility still missing        | 8/10        |
| 3       | Correct eligibility and historical calculations   | 10/10 logic |

**Key principles learned:**

- Account-level counts and transaction-level eligibility are different.
- `ROW_NUMBER()` can establish historical eligibility.
- `AVG()` combined with `LAG()` can calculate a previous-row rolling average.
- Validation against business rules can uncover mistakes in the supplied expected output.
- Intermediate calculation columns should not automatically appear in final reports.

Your identification of TransactionID `405` was particularly valuable: you caught an error in the original expected result.

### **6. Git checkpoint**

Save your final query as:

`06_Data_Engineering/task-045-banking-transaction-anomaly-detection.sql`

```
git add 06_Data_Engineering/task-045-banking-transaction-anomaly-detection.sql
git commit -m "Complete Task 45 banking transaction anomaly detection"
git push
```

**Final assessment: 10/10 for SQL logic.** Remove the extra output column and verify the five expected rows in SSMS to complete execution validation.

Task 45 is ready for that final verification. I will not assign Task 46 until you request it.

*/