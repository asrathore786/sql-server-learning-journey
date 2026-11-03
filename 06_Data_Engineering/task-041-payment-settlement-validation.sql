/*

## SQL Practice — Task 41

Your updated preference has been saved: Every SQL task must include the expected output table, along with the business requirement and sample data. Solutions and hints will remain withheld until you submit your attempt.

Task 41

SQL Server 2022

Banking Data Engineering

File: `06_Data_Engineering/task-041-payment-settlement-validation.sql`

Database: `DataEngineeringPracticeDB_Lite`

### Business requirement

A bank receives payment transactions from its core banking system and corresponding settlement records from a payment gateway.

The reconciliation team needs a report identifying payments that are not fully settled.

Return one row for every payment where the total successfully settled amount does not equal the original payment amount.

Your report must include payments with no settlement records, partially settled payments, over-settled payments, and payments whose settlement records are all unsuccessful.

Required output columns: `PaymentID`, `CustomerID`, `PaymentAmount`, `TotalSettledAmount`, `OutstandingAmount`, `SettlementStatus`.

Use these status values:

- `NOT_SETTLED` — no successful settlement amount.
- `PARTIALLY_SETTLED` — successful settlement total is greater than zero but less than the payment amount.
- `OVER_SETTLED` — successful settlement total exceeds the payment amount.

Fully settled payments must not appear.

### Dataset — Execute in SSMS

```

USE DataEngineeringPracticeDB_Lite;
GO

DROP TABLE IF EXISTS #PaymentSettlements;
DROP TABLE IF EXISTS #BankPayments;

CREATE TABLE #BankPayments (
    PaymentID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    PaymentAmount DECIMAL(12,2) NOT NULL
);

CREATE TABLE #PaymentSettlements (
    SettlementID INT PRIMARY KEY,
    PaymentID INT NOT NULL,
    SettlementAmount DECIMAL(12,2) NOT NULL,
    SettlementStatus VARCHAR(20) NOT NULL
);

INSERT INTO #BankPayments VALUES
(5001, 101, 10000.00),
(5002, 102, 15000.00),
(5003, 103, 20000.00),
(5004, 104, 12000.00),
(5005, 105, 8000.00),
(5006, 106, 25000.00),
(5007, 107, 18000.00),
(5008, 108, 5000.00),
(5009, 109, 14000.00),
(5010, 110, 9000.00);

INSERT INTO #PaymentSettlements VALUES
(1, 5001, 10000.00, 'SUCCESS'),
(2, 5002, 5000.00, 'SUCCESS'),
(3, 5002, 4000.00, 'SUCCESS'),
(4, 5003, 20000.00, 'FAILED'),
(5, 5004, 12000.00, 'SUCCESS'),
(6, 5005, 3000.00, 'SUCCESS'),
(7, 5005, 2000.00, 'FAILED'),
(8, 5006, 15000.00, 'SUCCESS'),
(9, 5006, 10000.00, 'SUCCESS'),
(10, 5007, 10000.00, 'SUCCESS'),
(11, 5007, 10000.00, 'SUCCESS'),
(12, 5009, 6000.00, 'SUCCESS'),
(13, 5009, 8000.00, 'FAILED'),
(14, 5010, 9000.00, 'SUCCESS');

```

### Expected output

Seven rows, ordered by PaymentID ascending. OutstandingAmount = PaymentAmount − TotalSettledAmount.

| PaymentID | CustomerID | PaymentAmount | TotalSettledAmount | OutstandingAmount | SettlementStatus  |
| --------- | ---------- | ------------- | ------------------ | ----------------- | ----------------- |
| 5002      | 102        | 15000.00      | 9000.00            | 6000.00           | PARTIALLY_SETTLED |
| 5003      | 103        | 20000.00      | 0.00               | 20000.00          | NOT_SETTLED       |
| 5005      | 105        | 8000.00       | 3000.00            | 5000.00           | PARTIALLY_SETTLED |
| 5007      | 107        | 18000.00      | 20000.00           | -2000.00          | OVER_SETTLED      |
| 5008      | 108        | 5000.00       | 0.00               | 5000.00           | NOT_SETTLED       |
| 5009      | 109        | 14000.00      | 6000.00            | 8000.00           | PARTIALLY_SETTLED |

Correction: The expected output contains 6 rows, as shown in the table, not seven.

### Acceptance criteria

Your query must return exactly those six payments, exclude unsuccessful settlement amounts from the total, preserve payments without settlement records, and avoid duplicate payment rows.

Write your SQL independently and share both your query and SSMS output. I will review the business logic, output grain, NULL handling, and reconciliation accuracy before assigning a score.

*/


WITH TotalAmount AS
(
SELECT 
    paymentID,
    SUM(SettlementAmount) AS TotalSettledAmount
FROM #PaymentSettlements
WHERE SettlementStatus = 'Success'
GROUP BY PaymentID
)

SELECT 
    B.PaymentID,
    B.CustomerID,
    B.PaymentAmount,
    COALESCE(P.TotalSettledAmount,0) AS TotalSettledAmount,
    B.PaymentAmount - COALESCE(P.TotalSettledAmount,0) AS OutstandingAmount,
    CASE
        WHEN COALESCE(P.TotalSettledAmount,0) = 0 THEN 'NOT_SETTLED'
        WHEN COALESCE(P.TotalSettledAmount,0) < B.PaymentAmount THEN 'PARTIALLY_SETTLED'
        WHEN B.PaymentAmount - COALESCE(P.TotalSettledAmount,0) < B.PaymentAmount THEN 'OVER_SETTLED'
    END AS SettlementStatus
FROM #BankPayments B
LEFT JOIN TotalAmount P
ON B.PaymentID = P.PaymentID
WHERE B.PaymentAmount - COALESCE(P.TotalSettledAmount,0) <> 0
ORDER BY B.PaymentID ASC;

/*

## Task 41 — Payment Settlement Validation: Final Review

Final score

# 10/10

Status

Completed & verified

Your SQL is correct, and the six rows in your submitted SSMS output match the expected results, including settlement amounts, outstanding balances, and status classifications.

### 1. Technical validation

| Validation criteria                      | Result |
| ---------------------------------------- | ------ |
| CTE aggregation                          | Pass   |
| Successful settlements only              | Pass   |
| `GROUP BY PaymentID`                     | Pass   |
| `LEFT JOIN` preserves unsettled payments | Pass   |
| `COALESCE` handles missing settlements   | Pass   |
| Partial settlement identification        | Pass   |
| Over-settlement identification           | Pass   |
| Fully settled payments excluded          | Pass   |
| Correct output grain                     | Pass   |
| Expected 6 records                       | Pass   |

### 2. Important observations

A. Your CTE design is correct.

```
WITH TotalAmount AS
(
    SELECT
        PaymentID,
        SUM(SettlementAmount) AS TotalSettledAmount
    FROM #PaymentSettlements
    WHERE SettlementStatus = 'Success'
    GROUP BY PaymentID
)
```

You aggregated settlement amounts before joining them to payments. This ensures one settlement total per `PaymentID` and prevents duplicate payment rows.

B. Your NULL handling is correct.

```
COALESCE(P.TotalSettledAmount, 0)
```

This correctly handles both payments without any settlement records and payments with only failed settlements.

C. Your CASE logic is correct.

You correctly distinguished:

- `NOT_SETTLED`
- `PARTIALLY_SETTLED`
- `OVER_SETTLED`

The negative outstanding amount for PaymentID `5007` is intentional and correctly indicates over-settlement.

### 3. Minor improvements

These are recommendations, not errors.

Improvement 1 — Simplify CASE conditions.

You do not need to check both `> 0` and `< PaymentAmount` after the first condition if you are working with nonnegative settlement amounts. However, your current conditions are explicit and readable.

Improvement 2 — Add deterministic ordering.

Your output matches the expected order, but SQL Server does not guarantee row ordering without an `ORDER BY`.

Add:

```
ORDER BY B.PaymentID ASC;
```

Improvement 3 — Consider negative settlement amounts.

In a production reconciliation process, refunds, reversals, or adjustments may introduce negative settlement amounts. Your current classification assumes ordinary nonnegative settlement totals, which is consistent with this exercise's dataset.

### 4. Learning record — Task 41

| Skill                             | Assessment |
| --------------------------------- | ---------- |
| Translating business requirements | Strong     |
| CTE construction                  | Strong     |
| Aggregation before joining        | Strong     |
| Handling missing records          | Strong     |
| Financial reconciliation logic    | Strong     |
| Conditional classification        | Strong     |
| Output validation                 | Correct    |

Progress observation: In Task 40, you needed multiple attempts to implement the correlated subquery and SELF JOIN approaches. In Task 41, your first submitted solution was correct and produced the expected reconciliation results.

That is positive evidence of improvement in translating requirements into SQL. It does not yet establish consistent performance across unfamiliar problems.

### 5. Git checkpoint

File: `06_Data_Engineering/task-041-payment-settlement-validation.sql`

Save your completed SQL, including the dataset and final query.

```
git add 06_Data_Engineering/task-041-payment-settlement-validation.sql
git commit -m "Complete Task 41 payment settlement validation"
git push
```

### Final assessment

Task 41: 10/10 — Completed.

You successfully combined CTE aggregation, conditional filtering, a `LEFT JOIN`, NULL handling, and reconciliation classification in one solution.

I will wait for your instruction before assigning Task 42.

*/