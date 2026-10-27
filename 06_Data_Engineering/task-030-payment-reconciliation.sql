/*

## Task 30 — Banking Data Engineering: JOIN Fan-Out & Financial Reconciliation

Intermediate–Advanced

SQL Server 2022

File name: `task-030-payment-reconciliation.sql`

Save folder: `06_Data_Engineering/`

Database: `DataEngineeringPracticeDB_Lite`

Tables: `dbo.Orders_Q30`, `dbo.Payments_Q30`, `dbo.PaymentStatusHistory_Q30`

### 1. Business requirement

A bank's Finance and Reconciliation team needs a customer-level report comparing order values against successfully settled payment amounts.

One order can have multiple payment attempts, and one payment can have multiple status updates.

Your SQL must prevent duplicate financial amounts caused by JOIN fan-out.

The report must:

1. Include every customer who has at least one order.
2. Calculate `TotalOrderAmount` from all their orders, counting each order exactly once.
3. Calculate `SuccessfulPaymentAmount` using payments whose latest status is `Success`.
4. Count each successful payment amount exactly once, regardless of its number of status updates.
5. Calculate `OutstandingAmount = TotalOrderAmount - SuccessfulPaymentAmount`.
6. Display zero for customers with no successful payments.
7. Sort by `CustomerID` ascending.

For this exercise, `Success` is treated as the qualifying settled status.

### 2. Test data setup

Setup file: `task-030-test-data-setup.sql`

Save it in `06_Data_Engineering/` and run it in SSMS.

```

USE DataEngineeringPracticeDB_Lite;
GO

-- Task 30: Banking Payment Reconciliation
-- Only Q30 practice tables will be replaced.

DROP TABLE IF EXISTS dbo.PaymentStatusHistory_Q30;
DROP TABLE IF EXISTS dbo.Payments_Q30;
DROP TABLE IF EXISTS dbo.Orders_Q30;
GO

CREATE TABLE dbo.Orders_Q30
(
    OrderID INT PRIMARY KEY,
    CustomerID VARCHAR(10) NOT NULL,
    OrderAmount DECIMAL(18,2) NOT NULL
);

CREATE TABLE dbo.Payments_Q30
(
    PaymentID INT PRIMARY KEY,
    OrderID INT NOT NULL,
    PaymentAmount DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (OrderID)
        REFERENCES dbo.Orders_Q30(OrderID)
);

CREATE TABLE dbo.PaymentStatusHistory_Q30
(
    StatusHistoryID INT IDENTITY(1,1) PRIMARY KEY,
    PaymentID INT NOT NULL,
    PaymentStatus VARCHAR(20) NOT NULL,
    UpdatedAt DATETIME2(0) NOT NULL,
    FOREIGN KEY (PaymentID)
        REFERENCES dbo.Payments_Q30(PaymentID)
);
GO

INSERT INTO dbo.Orders_Q30
    (OrderID, CustomerID, OrderAmount)
VALUES
    (1001, 'C1', 10000.00),
    (1002, 'C1',  5000.00),
    (1003, 'C2',  8000.00),
    (1004, 'C2',  4000.00),
    (1005, 'C3',  6000.00),
    (1006, 'C4',  3000.00);
GO

INSERT INTO dbo.Payments_Q30
    (PaymentID, OrderID, PaymentAmount)
VALUES
    (201, 1001, 6000.00),
    (202, 1001, 4000.00),
    (203, 1002, 5000.00),
    (204, 1003, 8000.00),
    (205, 1004, 2000.00),
    (206, 1004, 2000.00),
    (207, 1005, 6000.00);
GO

INSERT INTO dbo.PaymentStatusHistory_Q30
    (PaymentID, PaymentStatus, UpdatedAt)
VALUES
    (201, 'Pending', '2026-10-27T09:00:00'),
    (201, 'Success', '2026-10-27T09:10:00'),

    (202, 'Success', '2026-10-27T09:20:00'),

    (203, 'Success', '2026-10-27T10:00:00'),
    (203, 'Failed',  '2026-10-27T10:15:00'),

    (204, 'Pending', '2026-10-27T11:00:00'),
    (204, 'Success', '2026-10-27T11:20:00'),

    (205, 'Success', '2026-10-27T12:00:00'),

    (206, 'Pending', '2026-10-27T12:30:00'),
    (206, 'Failed',  '2026-10-27T12:45:00'),

    (207, 'Pending', '2026-10-27T13:00:00');
GO

-- Verify setup
SELECT * FROM dbo.Orders_Q30 ORDER BY OrderID;

SELECT * FROM dbo.Payments_Q30 ORDER BY PaymentID;

SELECT *
FROM dbo.PaymentStatusHistory_Q30
ORDER BY PaymentID, UpdatedAt;

```

The script replaces Q30 tables if they already exist. It does not modify Q27–Q29 data.

### 3. Expected output

Your final SQL must return:

| CustomerID | TotalOrderAmount | SuccessfulPaymentAmount | OutstandingAmount |
| ---------- | ---------------- | ----------------------- | ----------------- |
| C1         | 15,000.00        | 10,000.00               | 5,000.00          |
| C2         | 12,000.00        | 10,000.00               | 2,000.00          |
| C3         | 6,000.00         | 0.00                    | 6,000.00          |
| C4         | 3,000.00         | 0.00                    | 3,000.00          |

### 4. Your challenge

Write a single SQL Server query that produces the expected output.

You may use CTEs, derived tables, window functions, joins, and aggregation.

Restrictions: Do not hardcode amounts, do not use `SUM(DISTINCT OrderAmount)` to compensate for duplicate joins, and do not use separate customer-specific queries.

### 5. Evaluation criteria

I will assess your solution on correct output grain, latest-status identification, prevention of JOIN fan-out, financial aggregation accuracy, handling of unmatched payments, and SQL Server syntax.

Submit your SQL and actual SSMS output. I will review the query before providing corrections or a reference solution.

*/


WITH RankingSuccessCustomer AS
(
SELECT PaymentID,
    PaymentStatus,
    UpdatedAT,
    ROW_NUMBER() OVER(PARTITION BY PaymentID ORDER BY UpdatedAt DESC) RN
FROM dbo.PaymentStatusHistory_Q30
),
GetSuccessfulPayment AS
(
SELECT 
    P.orderID,
    SUM(P.PaymentAmount) AS SuccessfulPaymentAmount
   FROM dbo.Payments_Q30 P
INNER JOIN RankingSuccessCustomer S
ON P.PaymentID = S.PaymentID
AND PaymentStatus = 'success'
WHERE RN = 1
GROUP BY
    P.OrderID
),
OrderSuccessPayment AS 
(
SELECT O.CustomerID,
       SUM(P.SuccessfulPaymentAmount) AS SuccessfulPaymentAmount
FROM Orders_Q30 O
LEFT JOIN GetSuccessfulPayment P
ON P.OrderId = O.OrderID
GROUP BY O.CustomerID
)

SELECT 
    O.CustomerID,
    SUM(O.OrderAmount) AS TotalOrderAmount,
    COALESCE(S.SuccessfulPaymentAmount,0) AS SuccessfulPaymentAmount, 
    SUM(O.OrderAmount) - COALESCE(S.SuccessfulPaymentAmount,0) AS OutstandingAmount 
FROM Orders_Q30 O
INNER JOIN OrderSuccessPayment S
ON O.CustomerID = S.CustomerID
GROUP BY 
    O.customerID,
    S.SuccessfulPaymentAmount

/*

## Task 30 — SQL Code Review: Passed ✅

Logic score

# 10/10

Syntax

Valid

Assessment

Passed

Your query correctly addresses the main challenge: avoiding JOIN fan-out while calculating customer-level financial reconciliation amounts.

### 1. Expected output

| CustomerID | TotalOrderAmount | SuccessfulPaymentAmount | OutstandingAmount |
| ---------- | ---------------- | ----------------------- | ----------------- |
| C1         | 15,000.00        | 10,000.00               | 5,000.00          |
| C2         | 12,000.00        | 10,000.00               | 2,000.00          |
| C3         | 6,000.00         | 0.00                    | 6,000.00          |
| C4         | 3,000.00         | 0.00                    | 3,000.00          |

These are the expected results from the supplied test data; I have not independently executed your query in SSMS.

### 2. Detailed technical review

| Component                | Assessment                                                  |
| ------------------------ | ----------------------------------------------------------- |
| `RankingSuccessCustomer` | Correct latest-status ranking by `PaymentID`                |
| `GetSuccessfulPayment`   | Correctly sums only currently successful payments per order |
| `OrderSuccessPayment`    | Correctly aggregates successful payments to customer level  |
| Final `SELECT`           | Correctly calculates order totals independently             |
| `COALESCE()`             | Correctly handles customers with no successful payments     |
| `OutstandingAmount`      | Correct subtraction                                         |
| JOIN cardinality         | No fan-out affecting financial totals                       |

### 3. Why your approach works

Your query separates aggregation into appropriate stages.

PaymentStatusHistory

Latest status per PaymentID

GetSuccessfulPayment

Successful payment amount per OrderID

OrderSuccessPayment

Successful payment amount per CustomerID

Final reconciliation

One row per customer, without inflated order totals

The important design decision is that you aggregate payments to customer level before joining those totals back to `Orders_Q30`.

### 4. Production-level improvements

Your query is correct for this task, but I would recommend three refinements:

1. CTE naming: `RankingSuccessCustomer` is misleading because the ranking is by `PaymentID`, not by customer. A name such as `LatestPaymentStatus` would be clearer.
2. Column qualification: Use `S.PaymentStatus` and `S.RN` rather than unqualified column references.
3. Deterministic ranking: Add `StatusHistoryID DESC` after `UpdatedAt DESC` to handle timestamp ties.

Also, your final query does not explicitly sort by `CustomerID`. The task requires ascending order, so add:

```
ORDER BY O.CustomerID;
```

This is a minor requirement omission, not a reconciliation-calculation error.

### 5. Learning log

| Skill                 | Q28       | Q29    | Q30    |
| --------------------- | --------- | ------ | ------ |
| Latest-status logic   | Corrected | Passed | Passed |
| Window functions      | Corrected | Passed | Passed |
| JOIN cardinality      | —         | Passed | Passed |
| Zero-value handling   | —         | Passed | Passed |
| Financial aggregation | —         | —      | Passed |
| Output grain          | Corrected | Passed | Passed |

Your improvement is evident: you are now separating payment-level and customer-level calculations rather than aggregating everything after a multi-table join.

### 6. Save and commit

File: `06_Data_Engineering/task-030-payment-reconciliation.sql`

Database: `DataEngineeringPracticeDB_Lite`

```
git add 06_Data_Engineering/task-030-payment-reconciliation.sql
git commit -m "Task 30: Customer payment reconciliation without join fan-out"
git push
```

### Q30 — Final verification

One final conceptual question before Task 31:

Why would directly joining `Orders_Q30`, `Payments_Q30`, and `PaymentStatusHistory_Q30`, followed by `SUM(OrderAmount)`, potentially produce an incorrect `TotalOrderAmount`?

Explain in your own words, using OrderID `1001` as an example.

*/