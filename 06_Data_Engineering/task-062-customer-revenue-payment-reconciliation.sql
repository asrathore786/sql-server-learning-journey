/*
## Task 062 — Customer Revenue and Payment Reconciliation

Folder: `06_Data_Engineering`

Database: `DataEngineeringPracticeDB_Lite`

Filename

`task-062-customer-revenue-payment-reconciliation.sql`

&#x20; Copy filename&#x20;

## Business requirement

Your company wants a customer-level reconciliation report for calendar year 2026, using data available through 31 December 2026.

The Finance team needs to compare order values with successful payments and identify customers whose orders may be underpaid, unpaid, or overpaid.

Write a SQL query that returns one row per customer, including customers who have no orders.

### Required output columns

| Column                    | Business definition                                               |
| ------------------------- | ----------------------------------------------------------------- |
| `CustomerID`              | Unique customer identifier                                        |
| `CustomerName`            | Customer name                                                     |
| `TotalOrders`             | Number of qualifying orders                                       |
| `TotalOrderValue`         | Sum of qualifying order amounts                                   |
| `SuccessfulPaymentAmount` | Total amount from successful payments linked to qualifying orders |
| `UnpaidOrderCount`        | Number of orders with no successful payment                       |
| `OutstandingAmount`       | Total order value minus successful payment amount                 |
| `ReconciliationStatus`    | Customer-level reconciliation classification                      |

### Business rules

1. Include orders with `OrderDate >= '2026-01-01'` and `OrderDate < '2027-01-01'`.
2. Include all customers, even if they have no qualifying orders.
3. Count each qualifying order once. Multiple order items or payment records must not inflate order counts or order values.
4. Only payments with `PaymentStatus = 'Successful'` count toward successful payments. Other payment statuses must not contribute to the successful payment amount.
5. An order is considered unpaid if it has no successful payment record. For this task, do not classify partially paid orders as unpaid.
6. Calculate outstanding amount at customer level as total order value minus successful payment amount. A negative result indicates payments exceed order value.
7. Use these customer-level statuses:
   - `No Orders` — no qualifying orders.
   - `Unpaid Orders` — at least one order has no successful payment.
   - `Overpaid` — no unpaid orders and successful payments exceed total order value.
   - `Fully Reconciled` — no unpaid orders and successful payments equal total order value.
   - `Payment Mismatch` — no unpaid orders, but successful payments are less than total order value.
8. Return one row per customer, sorted by `CustomerID`.

Important: The unpaid-order classification is based on the existence of a successful payment, not whether the payment amount covers the full order amount. That distinction is intentional.

## Acceptance criteria

Before submitting your query, verify these conditions yourself:

- Customer count equals the number of rows returned.
- No customer appears more than once.
- Multiple payments do not duplicate order values.
- Customers without orders still appear.
- Failed or pending payments are excluded from successful payment totals.
- The five reconciliation statuses are applied in the specified priority order.

I am not providing hints or a solution upfront. Work in SSMS, test your query, and share both your SQL and its output. I will review your attempt before showing a corrected version.

## Your target before 1 November

Aim to finish this task and then spend the remaining SQL days on independent problem-solving and reviewing mistakes. You do not need to master every advanced SQL topic before beginning Python.

Your readiness test is whether you can translate a business requirement into a correct query, identify join-related duplication, handle missing data, and defend your calculations. If you can do that consistently, start Python on 1 November as planned.

*/


WITH CustomerOrderSummary AS
(
SELECT
	C.CustomerID,
	C.CustomerName,
	COUNT(O.CustomerID) AS TotalOrders,
	SUM(COALESCE(O.TotalAmount,0)) AS TotalOrderValue
FROM Customers C
	LEFT JOIN Orders O
		ON O.CustomerID = C.CustomerID
		AND O.OrderDate >= '2026-01-01' AND O.OrderDate < '2027-01-01'
GROUP BY
	C.CustomerID,
	C.CustomerName
),
PaymentAmount AS
(
SELECT
	O.CustomerID,
	SUM(COALESCE(P.PaymentAmount,0)) AS SuccessfulPaymentAmount
FROM Orders O
LEFT JOIN Payments P
		ON O.OrderID = P.OrderID
		AND P.PaymentStatus = 'Success'
WHERE O.OrderDate >= '2026-01-01' AND O.OrderDate < '2027-01-01'
GROUP BY
	O.CustomerID
),
UnpaidCustomer AS
(
SELECT 
	A.CustomerID,
	COUNT(A.OrderId) AS UnpaidOrderCount
FROM
(
SELECT 
	O.CustomerID,
	O.OrderID
FROM Orders O
WHERE NOT EXISTS(
	SELECT 1 FROM Payments P
	WHERE O.OrderID = P.OrderID 
	AND P.PaymentStatus = 'Success'
	)
AND O.OrderDate >= '2026-01-01' AND O.OrderDate < '2027-01-01'
) A
GROUP BY A.CustomerID
)
SELECT 
	Cust.CustomerID,
	Cust.CustomerName,
	C.TotalOrders,
	C.TotalOrderValue,
	COALESCE(P.SuccessfulPaymentAmount,0) AS SuccessfulPaymentAmount,
	COALESCE(U.UnpaidOrderCount,0) AS UnpaidOrderCount,
	C.TotalOrderValue - COALESCE(P.SuccessfulPaymentAmount,0) AS OutstandingAmount,
	CASE
		WHEN C.TotalOrders = 0 THEN 'No Orders'
		WHEN COALESCE(U.UnpaidOrderCount, 0) > 0 THEN 'Unpaid Orders'
		WHEN COALESCE(P.SuccessfulPaymentAmount,0) > C.TotalOrderValue THEN 'Overpaid'
		WHEN COALESCE(P.SuccessfulPaymentAmount,0) = C.TotalOrderValue THEN 'Fully Reconciled'
		WHEN COALESCE(P.SuccessfulPaymentAmount,0) < C.TotalOrderValue THEN 'Payment Mismatch'
	END AS ReconciliationStatus
FROM Customers Cust
	LEFT JOIN CustomerOrderSummary C
		ON C.CustomerID = Cust.CustomerID
	LEFT JOIN PaymentAmount P
		ON P.CustomerID = Cust.CustomerID
	LEFT JOIN UnpaidCustomer U
		ON U.CustomerID = Cust.CustomerID
ORDER BY 
	Cust.CustomerID ASC

/*
## Task 062 — Customer Revenue and Payment Reconciliation

Status: Output validation passed. ✅

Your latest output confirms that Noor Ali now has `SuccessfulPaymentAmount = 0.00` and the correct `No Orders` status. All 20 customers appear exactly once.

### Output summary

| Validation metric                   | Result |
| ----------------------------------- | ------ |
| Total customers                     | 20     |
| Customers with qualifying orders    | 19     |
| Customers without qualifying orders | 1      |
| Customers with unpaid orders        | 4      |
| Total unpaid orders                 | 13     |
| Fully reconciled customers          | 15     |
| Customers marked Overpaid           | 0      |
| Customers marked Payment Mismatch   | 0      |

One nuance: Meera Joshi has two qualifying orders with a total order value of ₹0 and successful payments of ₹0. Under your specified status rules, she is classified as `Fully Reconciled`. That is logically consistent with the query, although a production reconciliation policy might treat zero-value orders separately.

### Final task record

## Task 062 completed

File: `task-062-customer-revenue-payment-reconciliation.sql`

Folder: `06_Data_Engineering`

Skills demonstrated

- CTEs for separating order, payment, and unpaid-order aggregations.
- `LEFT JOIN` to preserve customers with no qualifying orders.
- `NOT EXISTS` to identify orders without successful payments.
- `COALESCE` for missing aggregate values.
- `CASE` for ordered business-rule classification.
- Exclusive date boundaries for the 2026 reporting period.

### Git commands

After saving your final query to the task file, run these commands in your repository's PowerShell terminal:

```
git add "06_Data_Engineering/task-062-customer-revenue-payment-reconciliation.sql"
git commit -m "Complete task 062 customer payment reconciliation"
git push origin main
```

I have not executed these commands. Also, your result output supports the checks above, but independent source-level reconciliation would still be needed to prove that every payment amount and unpaid-order count matches the underlying records.

*/