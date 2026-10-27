/*

## Task 29 — Banking Data Engineering: Customers With Zero Successful Payments

Intermediate

SQL Server 2022

File name: `task-029-customers-zero-successful-payments.sql`

Save folder: `06_Data_Engineering/`

Database: `DataEngineeringPracticeDB_Lite`

Tables: `dbo.Customers_Q29` and `dbo.PaymentStatusHistory_Q29`

### 1. Business requirement

A bank's Payments Operations team needs a customer-level reconciliation report.

The report must display every registered customer, including customers who have never made a payment or whose payments are not currently successful.

For each customer, calculate the number of payments whose latest recorded status is `Success`.

Business rules:

1. Every customer must appear exactly once.
2. A payment must be counted only if its latest status is `Success`.
3. Historical `Success` records must not be counted if the payment subsequently failed.
4. Customers with no payments must show `0`.
5. Customers with payments but no current successes must also show `0`.
6. Sort the final output by `CustomerID` ascending.

### 2. Test data setup

Setup file: `task-029-test-data-setup.sql`

Save this in the same folder and execute it in SSMS before attempting the task.

```

USE DataEngineeringPracticeDB_Lite;
GO

-- Task 29: Test Data Setup
-- Only Q29 practice tables are replaced.

DROP TABLE IF EXISTS dbo.PaymentStatusHistory_Q29;
DROP TABLE IF EXISTS dbo.Customers_Q29;
GO

CREATE TABLE dbo.Customers_Q29
(
    CustomerID VARCHAR(10) PRIMARY KEY,
    CustomerName VARCHAR(100) NOT NULL
);

CREATE TABLE dbo.PaymentStatusHistory_Q29
(
    StatusHistoryID INT IDENTITY(1,1) PRIMARY KEY,
    PaymentID INT NOT NULL,
    CustomerID VARCHAR(10) NOT NULL,
    PaymentStatus VARCHAR(20) NOT NULL,
    UpdatedAt DATETIME2(0) NOT NULL,
    FOREIGN KEY (CustomerID)
        REFERENCES dbo.Customers_Q29(CustomerID)
);
GO

INSERT INTO dbo.Customers_Q29
    (CustomerID, CustomerName)
VALUES
    ('C1', 'Amit'),
    ('C2', 'Neha'),
    ('C3', 'Rahul'),
    ('C4', 'Priya'),
    ('C5', 'Vikram'),
    ('C6', 'Simran');
GO

INSERT INTO dbo.PaymentStatusHistory_Q29
    (PaymentID, CustomerID, PaymentStatus, UpdatedAt)
VALUES
    (101, 'C1', 'Pending', '2026-10-27T10:00:00'),
    (101, 'C1', 'Success', '2026-10-27T10:10:00'),

    (102, 'C1', 'Success', '2026-10-27T11:00:00'),
    (102, 'C1', 'Failed',  '2026-10-27T11:15:00'),

    (103, 'C2', 'Pending', '2026-10-27T12:00:00'),
    (103, 'C2', 'Success', '2026-10-27T12:20:00'),

    (104, 'C2', 'Success', '2026-10-27T13:00:00'),

    (105, 'C3', 'Pending', '2026-10-27T14:00:00'),
    (105, 'C3', 'Failed',  '2026-10-27T14:20:00'),

    (106, 'C4', 'Success', '2026-10-27T15:00:00'),
    (106, 'C4', 'Failed',  '2026-10-27T15:30:00'),

    (107, 'C4', 'Success', '2026-10-27T16:00:00'),

    (108, 'C6', 'Pending', '2026-10-27T17:00:00');
GO

-- Verify customer data
SELECT *
FROM dbo.Customers_Q29
ORDER BY CustomerID;

-- Verify payment history
SELECT *
FROM dbo.PaymentStatusHistory_Q29
ORDER BY PaymentID, UpdatedAt;

```

Warning: The setup replaces existing Q29 tables. It does not modify Q27 or Q28 tables.

### 3. Expected output

Your SQL must produce exactly these six rows:

| CustomerID | CustomerName | SuccessfulPaymentCount |
| ---------- | ------------ | ---------------------- |
| C1         | Amit         | 1                      |
| C2         | Neha         | 2                      |
| C3         | Rahul        | 0                      |
| C4         | Priya        | 1                      |
| C5         | Vikram       | 0                      |
| C6         | Simran       | 0                      |

### 4. Your challenge

Write a SQL Server query that produces the expected result using the supplied tables.

You may use CTEs, derived tables, window functions, and joins as you consider appropriate.

Restrictions: Do not hardcode the expected counts, and do not use separate queries for individual customers.

### 5. Evaluation criteria

I will assess your submission on:

- Correct identification of the latest payment status.
- Preservation of all six customers.
- Correct handling of customers without payments.
- Accurate aggregation without duplicate counts.
- Correct output grain and SQL Server syntax.

Submit your SQL query and SSMS result. I will review it strictly, identify any errors, and update your learning log. No hints or solution before your attempt.

*/

WITH CTE_1 AS
(
SELECT 
    P.customerID,
    P.PaymentStatus,
    P.UpdatedAt,
    ROW_NUMBER() OVER(PARTITION BY P.paymentID ORDER BY UpdatedAT Desc) AS RN
FROM dbo.PaymentStatusHistory_Q29 P
)

SELECT 
    C.CustomerID,
    C.CustomerName,
    COUNT(CT.CustomerID) AS SuccessfulPaymentCount
FROM dbo.Customers_Q29 C
LEFT JOIN CTE_1 CT
ON C.customerId = CT.customerID
AND CT.RN = 1
AND PaymentStatus = 'success' 
GROUP BY 
    C.CustomerID,
    C.CustomerName

/*

## Task 29 — SQL Code Review: Passed ✅

Logic score

# 10/10

SQL syntax

## Valid

Assessment

Passed

Your query correctly handles the main challenge: preserving all customers while counting only payments whose latest status is `Success`.

### 1. Expected result

| CustomerID | CustomerName | SuccessfulPaymentCount |
| ---------- | ------------ | ---------------------- |
| C1         | Amit         | 1                      |
| C2         | Neha         | 2                      |
| C3         | Rahul        | 0                      |
| C4         | Priya        | 1                      |
| C5         | Vikram       | 0                      |
| C6         | Simran       | 0                      |

Your query should return exactly these six rows against the supplied Q29 test data.

### 2. Technical assessment

| Evaluation criteria                                    | Result        |
| ------------------------------------------------------ | ------------- |
| CTE implementation                                     | &#x20;Correct |
| `ROW_NUMBER()` partitioned by `PaymentID`              | &#x20;Correct |
| Latest status selection (`RN = 1`)                     | &#x20;Correct |
| `LEFT JOIN` preserves all customers                    | &#x20;Correct |
| Status filtering inside `ON`                           | &#x20;Correct |
| `COUNT(CT.CustomerID)` returns zero for unmatched rows | &#x20;Correct |
| Customer-level `GROUP BY`                              | &#x20;Correct |

### 3. What you did particularly well

A. Correct `LEFT JOIN` filtering

```
ON C.CustomerID = CT.CustomerID
AND CT.RN = 1
AND CT.PaymentStatus = 'Success'
```

You placed the conditions inside the `ON` clause rather than the outer `WHERE` clause.

This is important because putting `CT.PaymentStatus = 'Success'` in the outer `WHERE` would eliminate customers with no matching successful payment.

B. Correct COUNT expression

```
COUNT(CT.CustomerID)
```

This counts non-NULL matching rows. For a customer without successful payments, the `LEFT JOIN` produces NULL values for the CTE columns, resulting in a count of zero.

Using `COUNT(*)` here would incorrectly produce `1` for customers with no matches.

### 4. Production improvements

Your solution is correct. Two minor refinements would improve maintainability:

- Qualify `PaymentStatus` as `CT.PaymentStatus` for clarity.
- Add `StatusHistoryID DESC` as a secondary window-ordering key when timestamps can tie. That requires including the column in the CTE's window ordering.

Neither is a failure against the supplied test data.

### 5. Learning log

| Concept                     | Assessment                |
| --------------------------- | ------------------------- |
| Latest record per payment   | Mastered in this exercise |
| CTE + window function       | Correct                   |
| `LEFT JOIN` vs `INNER JOIN` | Correct                   |
| `ON` vs `WHERE` filtering   | Correct                   |
| Zero-count customers        | Correct                   |
| Output grain                | Correct                   |

Progress observation: In Q28 you initially partitioned by `CustomerID` and filtered status before ranking. In Q29, you independently avoided both errors and correctly preserved unmatched customers.

This is meaningful improvement in SQL query design.

### 6. Save and commit

File: `06_Data_Engineering/task-029-customers-zero-successful-payments.sql`

Database: `DataEngineeringPracticeDB_Lite`

```
git add 06_Data_Engineering/task-029-customers-zero-successful-payments.sql
git commit -m "Task 29: Count latest successful payments including zero-payment customers"
git push
```

Final status: Task 29 passes logical and syntax review. Actual SSMS execution has not been independently verified.

Next, Task 30 will increase difficulty by introducing JOIN fan-out and financial reconciliation, where an apparently correct aggregation can produce inflated monetary totals.

*/

