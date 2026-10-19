/*

# Task 037 — Payment Reconciliation and Exception Detection

Intermediate → Advanced

Task 037

Database: `DataEngineeringPracticeDB`

Save folder: `06_Data_Engineering`

Filename: `task-037-payment-reconciliation-exception-detection.sql`

Primary skills: `JOIN`, `GROUP BY`, `CASE`, aggregate functions, data-quality analysis.

## Business requirement

You are a Data Engineer working for a bank. The Finance Operations team needs a payment reconciliation report to identify orders whose recorded payment information may require investigation.

Use the `Orders` and `Payments` tables to produce a report with one row per order for every order that meets at least one of the following conditions:

1. The order has no payment record.
2. At least one associated payment has a status of `Failed`.
3. At least one associated payment has a status of `Pending`.
4. The total recorded payment amount differs from the order's `TotalAmount`.

For this task, compare the order amount against the sum of all associated payment amounts, regardless of payment status. Do not assume that an order has only one payment record.

## Expected output

Your result must contain these columns in this order:

| Column                 | Meaning                                                     |
| ---------------------- | ----------------------------------------------------------- |
| `OrderID`              | Unique order identifier                                     |
| `OrderDate`            | Date of the order                                           |
| `OrderStatus`          | Status recorded in `Orders`                                 |
| `OrderAmount`          | Amount recorded for the order                               |
| `PaymentCount`         | Number of payment records associated with the order         |
| `TotalPaymentAmount`   | Sum of all associated payment amounts                       |
| `FailedPaymentCount`   | Number of failed payment records                            |
| `PendingPaymentCount`  | Number of pending payment records                           |
| `AmountDifference`     | `OrderAmount - TotalPaymentAmount`                          |
| `ReconciliationStatus` | Classification explaining why the order needs investigation |

Use these classification labels, in the following priority order:

1. `Missing Payment`
2. `Failed Payment`
3. `Pending Payment`
4. `Amount Mismatch`

An order meeting multiple conditions should receive the first applicable classification in this list.

## Rules

- Include all orders that meet at least one exception condition.
- Do not exclude failed or pending payments from `TotalPaymentAmount`.
- Orders with no payments must still appear in the report.
- Return exactly one row per `OrderID`.
- Sort by `OrderID` ascending.
- Do not modify the source tables.

## Your task

Write the SQL query that satisfies the business requirement.

Before submitting, consider how you will handle orders with no payment records, how to aggregate multiple payments, and how to classify exceptions in the required priority order. I will review your query first and will not reveal the solution before your attempt.

consider how you will handle orders with no payment records --> I will use order table with payment table by Left join so all the order with no payment considered as No payment record available
, how to aggregate multiple payments --> i will aggregate payment based on OrderID , and 
how to classify exceptions in the required priority order --> I will use the union all to consolidate all type then use rank function Top 1 will be considered as the 

*/

WITH Payment_Summary AS
(
SELECT 
	P.OrderID,
	COUNT(P.PaymentID) AS PaymentCount,
	SUM(p.PaymentAmount) AS TotalPaymentAmount,
	SUM(CASE WHEN P.PaymentStatus = 'Failed' THEN 1 ELSE 0 END) AS FailedPaymentCount,
	SUM(CASE WHEN P.PaymentStatus = 'Pending' THEN 1 ELSE 0 END) AS PendingPaymentCount
FROM Payments P
GROUP BY P.OrderID
),
reconciliation AS
(
SELECT 
	O.OrderID,
	O.OrderDate,
	O.Status,
	O.TotalAmount,
	COALESCE(PS.PaymentCount, 0) AS PaymentCount,
	COALESCE(PS.TotalPaymentAmount,0) AS TotalPaymentAmount,
	COALESCE(PS.FailedPaymentCount,0) AS FailedPaymentCount,
	COALESCE(PS.PendingPaymentCount,0) AS PendingPaymentCount,
	O.TotalAmount - COALESCE(PS.TotalPaymentAmount, 0) AS AmountDifference
FROM Orders O
	LEFT JOIN Payment_Summary PS
		ON O.OrderID = PS.OrderID
)

SELECT *,
	CASE 
		WHEN PaymentCount = 0 THEN 'Missing Payment'
		WHEN FailedPaymentCount > 0 THEN 'Failed Payment'
		WHEN PendingPaymentCount > 0 THEN 'Pending Payment'
		WHEN AmountDifference <> 0 THEN 'Amount Mismatch'
		ELSE 'No Exception'
	END AS ReconciliationStatus
	FROM reconciliation
WHERE PaymentCount = 0
   OR FailedPaymentCount > 0
   OR PendingPaymentCount > 0
   OR AmountDifference <> 0
ORDER BY OrderID ASC;



/*

Understood. From now on, after every successfully submitted SQL practice task, I’ll provide the complete task record, not just a brief review. I’ll use the following structure for Task 037 and future tasks.

# Task 037 — Payment Reconciliation and Exception Detection

Logic approved

SQL Server 2022

Data Engineering

## 1. Task details

- Database: `DataEngineeringPracticeDB`
- Folder: `06_Data_Engineering`
- Filename: `task-037-payment-reconciliation-exception-detection.sql`
- Difficulty: Intermediate
- Primary concepts: CTEs, aggregation, conditional aggregation, `LEFT JOIN`, `COALESCE`, `CASE`, exception detection.

## 2. Business requirement

Identify orders that require payment reconciliation because at least one of these conditions applies:

1. No payment record exists.
2. At least one payment has Failed status.
3. At least one payment has Pending status.
4. The sum of all payment amounts differs from the order amount.

Return one row per affected order with its order details, payment counts, total payment amount, failed and pending counts, amount difference, and reconciliation status.

Apply classification priority in this order:

1. `Missing Payment`
2. `Failed Payment`
3. `Pending Payment`
4. `Amount Mismatch`

Sort the result by `OrderID` ascending.

## 3. Your submitted query

```

WITH Payment_Summary AS
(
    SELECT 
        P.OrderID,
        COUNT(P.PaymentID) AS PaymentCount,
        SUM(P.PaymentAmount) AS TotalPaymentAmount,
        SUM(CASE WHEN P.PaymentStatus = 'Failed'
                 THEN 1 ELSE 0 END) AS FailedPaymentCount,
        SUM(CASE WHEN P.PaymentStatus = 'Pending'
                 THEN 1 ELSE 0 END) AS PendingPaymentCount
    FROM dbo.Payments AS P
    GROUP BY P.OrderID
),
Reconciliation AS
(
    SELECT 
        O.OrderID,
        O.OrderDate,
        O.Status,
        O.TotalAmount,
        COALESCE(PS.PaymentCount, 0) AS PaymentCount,
        COALESCE(PS.TotalPaymentAmount, 0) AS TotalPaymentAmount,
        COALESCE(PS.FailedPaymentCount, 0) AS FailedPaymentCount,
        COALESCE(PS.PendingPaymentCount, 0) AS PendingPaymentCount,
        O.TotalAmount
            - COALESCE(PS.TotalPaymentAmount, 0) AS AmountDifference
    FROM dbo.Orders AS O
    LEFT JOIN Payment_Summary AS PS
        ON O.OrderID = PS.OrderID
)
SELECT *,
    CASE 
        WHEN PaymentCount = 0 THEN 'Missing Payment'
        WHEN FailedPaymentCount > 0 THEN 'Failed Payment'
        WHEN PendingPaymentCount > 0 THEN 'Pending Payment'
        WHEN AmountDifference <> 0 THEN 'Amount Mismatch'
    END AS ReconciliationStatus
FROM Reconciliation
WHERE PaymentCount = 0
   OR FailedPaymentCount > 0
   OR PendingPaymentCount > 0
   OR AmountDifference <> 0
ORDER BY OrderID ASC;

```

Review note: Your submitted logic is correct. I standardized the spelling of the CTE and the `Amount Mismatch` label in this documented version. I have not independently executed this query.

## 4. Expected output structure

| Column                 | Meaning                                 |
| ---------------------- | --------------------------------------- |
| `OrderID`              | Unique order identifier                 |
| `OrderDate`            | Date of the order                       |
| `Status`               | Current order status                    |
| `TotalAmount`          | Amount expected for the order           |
| `PaymentCount`         | Number of payment records               |
| `TotalPaymentAmount`   | Sum of all payment amounts              |
| `FailedPaymentCount`   | Number of Failed payments               |
| `PendingPaymentCount`  | Number of Pending payments              |
| `AmountDifference`     | Order amount minus total payment amount |
| `ReconciliationStatus` | Highest-priority applicable exception   |

## 5. Validation against your test data

The following results are supported by the diagnostic output you shared. They are the expected classifications from your business rules, rather than a reproduced full output from a fresh execution of the final query.

| OrderID | Order amount | Payment count | Total paid | Failed | Pending | Difference | Expected status |
| ------- | ------------ | ------------- | ---------- | ------ | ------- | ---------- | --------------- |
| 10001   | 100.00       | 0             | 0.00       | 0      | 0       | 100.00     | Missing Payment |
| 10002   | 200.00       | 1             | 200.00     | 1      | 0       | 0.00       | Failed Payment  |
| 10003   | 300.00       | 1             | 300.00     | 0      | 1       | 0.00       | Pending Payment |
| 10004   | 400.00       | 1             | 350.00     | 0      | 0       | 50.00      | Amount Mismatch |
| 10007   | 700.00       | 1             | 750.00     | 0      | 0       | -50.00     | Amount Mismatch |
| 10008   | 800.00       | 2             | 800.00     | 1      | 1       | 0.00       | Failed Payment  |
| 10009   | 900.00       | 1             | 850.00     | 1      | 0       | 50.00      | Failed Payment  |
| 10010   | 1,000.00     | 2             | 900.00     | 0      | 1       | 100.00     | Pending Payment |

Orders `10005` and `10006` are correctly excluded because their totals match and neither has Failed or Pending payments.

## 6. What you did well

- Aggregated payment records before joining them to orders, avoiding duplication of order-level amounts.
- Used `LEFT JOIN` so orders without payments remain visible.
- Used `COALESCE` to convert missing payment aggregates to zero.
- Applied conditional aggregation to count payment statuses.
- Used the required exception priority in the `CASE` expression.
- Used the same exception conditions in the `WHERE` clause to exclude normal orders.

## 7. What to improve

Output clarity: Alias `O.Status` as `OrderStatus` and `O.TotalAmount` as `OrderAmount`.

Consistency: Use consistent spelling and capitalization for CTE names and status labels.

Validation: Check both individual exception records and aggregate counts. In production reconciliation, also distinguish payment statuses when determining settled amounts, depending on the business definition.

Testing: Include cases for missing payments, multiple payments, failed and pending payments, underpayments, overpayments, and normal orders. Your test data already covers these scenarios.

## 8. Skill assessment

Task score

# 9/10

Assessment of the submitted query's logic and SQL design, not a measured overall SQL proficiency score.

Your strongest area in this task was translating business reconciliation rules into SQL. The next step is to improve test coverage and make the output easier to maintain and audit.

## 9. Git workflow

Save the query using the filename above in your `06_Data_Engineering` folder. After saving, stage and commit it with:

```

git add "06_Data_Engineering/task-037-payment-reconciliation-exception-detection.sql"
git commit -m "Add payment reconciliation exception detection"
git push origin main

```

Run these commands from the repository root. They assume the file is saved at the stated relative path and that your branch is `main`.

Going forward: Every successful SQL submission will receive this complete record: task metadata, business requirement, your submitted query, review and corrections, validation results, concept assessment, improvement areas, and Git commands. I’ll distinguish confirmed SSMS output from expected results and won’t claim a query has executed successfully unless the evidence supports that conclusion.

*/