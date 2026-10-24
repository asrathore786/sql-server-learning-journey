/*

## Task 063 — Order Payment Reconciliation: Exception Detection

## Task 063

Folder: `06_Data_Engineering`

Intermediate–Advanced

Filename

`task-063-order-payment-exception-detection.sql`

Database

`DataEngineeringPracticeDB_Lite`

### Business requirement

The finance team needs an exception report to identify orders with payment inconsistencies for the 2026 calendar year. The report will be used to prioritize orders that need investigation.

Write a SQL query that returns one row per qualifying order, including orders with no payment records.

Include these columns:

| Column                    | Requirement                                                                   |
| ------------------------- | ----------------------------------------------------------------------------- |
| `OrderID`                 | Unique order identifier                                                       |
| `CustomerID`              | Customer who placed the order                                                 |
| `OrderDate`               | Order date                                                                    |
| `OrderValue`              | Order's recorded `TotalAmount`                                                |
| `PaymentRecordCount`      | Total payment records associated with the order, regardless of payment status |
| `SuccessfulPaymentCount`  | Number of payment records with `PaymentStatus = 'Success'`                    |
| `SuccessfulPaymentAmount` | Sum of successful payment amounts; return zero when none exist                |
| `FailedPaymentCount`      | Number of payment records with `PaymentStatus = 'Failed'`                     |
| `PaymentDifference`       | `OrderValue - SuccessfulPaymentAmount`                                        |
| `ExceptionType`           | Classification based on the rules below                                       |

### Exception classification rules

Apply these rules in the listed priority order:

1. `No Payment Records` — the order has no payment records.
2. `Failed Payments Only` — the order has payment records but no successful payment records.
3. `Multiple Successful Payments` — the order has more than one successful payment record.
4. `Overpaid` — successful payment amount exceeds the order value.
5. `Underpaid` — successful payment amount is less than the order value.
6. `Reconciled` — successful payment amount equals the order value.

### Filters and constraints

- Include orders where `OrderDate >= '2026-01-01' AND OrderDate < '2027-01-01'`.
- Include orders even when no payment records exist.
- Count payment records accurately; do not multiply amounts or counts through joins.
- Treat only `'Success'` as a successful payment and `'Failed'` as a failed payment.
- Return one row per order, sorted by `OrderID` ascending.
- Use SQL Server syntax.

### Your task

Solve it independently in SSMS. You may use CTEs, subqueries, conditional aggregation, or another valid approach.

I will not provide hints or a solution before you attempt it. Share your SQL query when you're ready, and I'll review the logic, edge cases, and correctness before asking you to validate the output.

*/


WITH OrderSummary AS
(
SELECT 
	O.CustomerID,
	O.OrderID,
	O.OrderDate,
	O.TotalAmount,
	COUNT(P.OrderId) AS PaymentRecordCount
FROM Orders O
LEFT JOIN Payments P
	ON P.OrderID = O.OrderID
WHERE O.OrderDate >= '2026-01-01' AND O.OrderDate < '2027-01-01'
GROUP BY 
	O.CustomerID,
	O.OrderID,
	O.OrderDate,
	O.TotalAmount
),
SuccessPaymentSummary AS
(
SELECT 
	P.OrderID,
	COUNT(P.OrderID) AS SuccessfulPaymentCount,
	COALESCE(SUM(P.PaymentAmount),0) AS SuccessfulPaymentAmount
FROM Payments P
WHERE P.PaymentStatus = 'Success'
GROUP BY
	P.OrderID
),
FailedPaymentSummary AS
(
SELECT 
	P.OrderID,
	COUNT(P.OrderID) AS FailedPaymentCount
FROM Payments P
WHERE P.PaymentStatus = 'Failed'
GROUP BY
	P.OrderID
)

SELECT 
	O.OrderID,
	O.CustomerID,
	O.OrderDate,
	O.TotalAmount,
	O.PaymentRecordCount,
	COALESCE(S.SuccessfulPaymentCount,0) AS SuccessfulPaymentCount,
	COALESCE(S.SuccessfulPaymentAmount,0) AS SuccessfulPaymentAmount,
	COALESCE(F.FailedPaymentCount,0) AS FailedPaymentCount,
	O.TotalAmount - COALESCE(S.SuccessfulPaymentAmount,0) AS PaymentDifference,
	CASE
		WHEN O.PaymentRecordCount = 0 THEN 'No Payment Records'
		WHEN COALESCE(S.SuccessfulPaymentCount,0) = 0 AND O.PaymentRecordCount > 0 THEN 'Failed Payments Only'
		WHEN O.PaymentRecordCount > 0 AND COALESCE(S.SuccessfulPaymentCount,0) > 1 THEN 'Multiple Successful Payments'
		WHEN O.TotalAmount < COALESCE(S.SuccessfulPaymentAmount,0) THEN 'Overpaid'
		WHEN COALESCE(S.SuccessfulPaymentAmount,0) < O.TotalAmount THEN 'Underpaid'
		WHEN COALESCE(S.SuccessfulPaymentAmount,0) = O.TotalAmount THEN 'Reconciled'
	END AS ExceptionType
FROM OrderSummary O
LEFT JOIN SuccessPaymentSummary S
	ON O.OrderID = S.OrderID
LEFT JOIN FailedPaymentSummary F
	ON F.OrderID = O.OrderID
ORDER BY O.OrderID ASC

/*
# Task 063 — Order Payment Reconciliation: Exception Detection

## Task completion report

Query review complete

Folder: `06_Data_Engineering`

Filename: `task-063-order-payment-exception-detection.sql`

Database: `DataEngineeringPracticeDB_Lite`

Overall assessment: Your query is logically sound for the specified business rules, and the supplied output demonstrates several important payment-reconciliation scenarios. Some edge cases still need explicit verification.

## 1. What you got right

- One row per qualifying order: The `LEFT JOIN` retains orders even when no payment records exist.
- Correct date filtering: The half-open date range includes January 1 through December 31, 2026, while excluding November 1, 2027, and later dates. Specifically, an order dated November 1, 2026, is included; the upper boundary is January 1, 2027.
- Avoiding join fan-out: Payment records, successful payments, and failed payments are summarized separately before the final joins. This prevents successful payment amounts from being multiplied by other payment records.
- Correct payment counts: All payment records contribute to `PaymentRecordCount`; only `Success` records contribute to `SuccessfulPaymentCount` and `SuccessfulPaymentAmount`, and only `Failed` records contribute to `FailedPaymentCount`.
- Correct classification priority: `Multiple Successful Payments` takes precedence over `Overpaid`, as required.
- NULL handling: `COALESCE` converts missing payment aggregates to zero for the output and reconciliation calculations.

## 2. Important cases verified in your output

| Order ID | Scenario                                                              | Expected classification      | Result  |
| -------- | --------------------------------------------------------------------- | ---------------------------- | ------- |
| 1000     | Zero-value order, no payment records                                  | No Payment Records           | Correct |
| 1001     | Failed payment only                                                   | Failed Payments Only         | Correct |
| 1002     | Payment exists, no successful payment                                 | Failed Payments Only         | Correct |
| 1003     | Successful payment below order value                                  | Underpaid                    | Correct |
| 1004     | Successful payment equals order value                                 | Reconciled                   | Correct |
| 1005     | Two successful payments, total equals order value                     | Multiple Successful Payments | Correct |
| 1006     | Multiple successful payments, total exceeds order value               | Multiple Successful Payments | Correct |
| 1009     | Three successful payments                                             | Multiple Successful Payments | Correct |
| 1036     | Order dated November 1, 2026                                          | Included in 2026 results     | Correct |
| 9001     | Order without payment records                                         | No Payment Records           | Correct |
| 9101     | Pending payment only                                                  | Failed Payments Only         | Correct |
| 9102     | Successful and failed payments; successful amount equals order value  | Reconciled                   | Correct |
| 9103     | Successful payment exceeds order value                                | Overpaid                     | Correct |
| 9104     | Successful and failed payments; successful amount below order value   | Underpaid                    | Correct |
| 9105     | Failed and pending payments, no successful payment                    | Failed Payments Only         | Correct |
| 9106     | Successful and pending payments; successful amount equals order value | Reconciled                   | Correct |

Important correction: Order `1036`, dated `2026-11-01`, belongs in the results because it falls within calendar year 2026. The excluded upper boundary is `2027-01-01`. Your earlier result correctly included order `1036`.

## 3. Validation gaps and improvements

A. Confirm the result count.

The full output previously supplied contains 68 rows, based on the listed records: 55 original orders, seven orders numbered 9001–9007, and six orders numbered 9101–9106. A prior review stated 63 qualifying orders, which does not match that list. Order `1037` is also absent from the supplied output. Re-run the query and check the actual row count before recording the final count as verified.

B. Edge-case validation.

The additional test orders demonstrate the following:

- Pending-only order: `9101`
- Successful and failed payments on the same order: `9102` and `9104`
- Successful payment exceeding order value: `9103`
- Failed and pending payments with no success: `9105`
- Successful and pending payments together: `9106`

These cases are demonstrated in the output you provided. However, you should still verify whether the dataset contains an order with multiple successful payments whose total equals or falls below the order value, and whether the output contains every expected qualifying order.

C. SQL improvement.

Use explicit schema names such as `dbo.Orders` and `dbo.Payments`. This makes the intended objects clear and improves consistency in production-style SQL scripts.

## 4. Final reviewed query

The following is the cleaned-up version of your query, retaining the business logic and using explicit schema names. It is the reviewed version; I have not independently executed it against your database.

```

WITH OrderSummary AS
(
    SELECT
        O.CustomerID,
        O.OrderID,
        O.OrderDate,
        O.TotalAmount,
        COUNT(P.OrderID) AS PaymentRecordCount
    FROM dbo.Orders AS O
    LEFT JOIN dbo.Payments AS P
        ON P.OrderID = O.OrderID
    WHERE O.OrderDate >= '20260101'
      AND O.OrderDate <  '20270101'
    GROUP BY
        O.CustomerID,
        O.OrderID,
        O.OrderDate,
        O.TotalAmount
),
SuccessPaymentSummary AS
(
    SELECT
        P.OrderID,
        COUNT(*) AS SuccessfulPaymentCount,
        SUM(P.PaymentAmount) AS SuccessfulPaymentAmount
    FROM dbo.Payments AS P
    WHERE P.PaymentStatus = 'Success'
    GROUP BY P.OrderID
),
FailedPaymentSummary AS
(
    SELECT
        P.OrderID,
        COUNT(*) AS FailedPaymentCount
    FROM dbo.Payments AS P
    WHERE P.PaymentStatus = 'Failed'
    GROUP BY P.OrderID
)
SELECT
    O.OrderID,
    O.CustomerID,
    O.OrderDate,
    O.TotalAmount,
    O.PaymentRecordCount,
    COALESCE(S.SuccessfulPaymentCount, 0)
        AS SuccessfulPaymentCount,
    COALESCE(S.SuccessfulPaymentAmount, 0)
        AS SuccessfulPaymentAmount,
    COALESCE(F.FailedPaymentCount, 0)
        AS FailedPaymentCount,
    O.TotalAmount
        - COALESCE(S.SuccessfulPaymentAmount, 0)
        AS PaymentDifference,
    CASE
        WHEN O.PaymentRecordCount = 0
            THEN 'No Payment Records'
        WHEN COALESCE(S.SuccessfulPaymentCount, 0) = 0
            THEN 'Failed Payments Only'
        WHEN COALESCE(S.SuccessfulPaymentCount, 0) > 1
            THEN 'Multiple Successful Payments'
        WHEN COALESCE(S.SuccessfulPaymentAmount, 0) > O.TotalAmount
            THEN 'Overpaid'
        WHEN COALESCE(S.SuccessfulPaymentAmount, 0) < O.TotalAmount
            THEN 'Underpaid'
        WHEN COALESCE(S.SuccessfulPaymentAmount, 0) = O.TotalAmount
            THEN 'Reconciled'
    END AS ExceptionType
FROM OrderSummary AS O
LEFT JOIN SuccessPaymentSummary AS S
    ON S.OrderID = O.OrderID
LEFT JOIN FailedPaymentSummary AS F
    ON F.OrderID = O.OrderID
ORDER BY O.OrderID ASC;

```

### Why this approach works

The key design decision is to aggregate payment data at the order grain before joining it to the order-level result.

- `OrderSummary` produces one row per qualifying order.
- `SuccessPaymentSummary` produces one row per order with successful payments.
- `FailedPaymentSummary` produces one row per order with failed payments.
- The final query combines those summaries without multiplying payment amounts.
- The `CASE` expression applies exception classifications in the specified priority order.

One subtle point: `Failed Payments Only` is the required business label for any order with payment records but no successful payments. Therefore, an order containing only pending payments receives that label even though no payment actually has a `Failed` status.

## 5. Learning log

| Area                       | Review and lesson                                                                                                        |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| Query structure            | CTEs make complex reconciliation logic easier to isolate and review.                                                     |
| Join cardinality           | Aggregate one-to-many payment records before joining them to order-level results to avoid fan-out.                       |
| Conditional classification | `CASE` order matters when multiple conditions could apply to the same order.                                             |
| NULL handling              | Missing payment aggregates should be treated as zero for calculations and comparisons.                                   |
| Payment statuses           | Count `Success`, `Failed`, and all payment records separately because each metric answers a different business question. |
| Date boundaries            | Use `>= '20260101' AND < '20270101'` for a full calendar year, including when the date column contains a time component. |
| Validation discipline      | Reconcile the actual row count and missing IDs rather than assuming the output is complete.                              |

Correction points / learning log

- The earlier review identified an unnecessary `EXISTS` condition in the original attempt. Avoid adding existence checks when the aggregation and join structure already handles the requirement.
- Keep `Multiple Successful Payments` ahead of overpayment and underpayment checks.
- The output is consistent with the supplied examples, but the total row count and missing order `1037` still require investigation.

## 6. Save the task

Filename

`task-063-order-payment-exception-detection.sql`

Copy

Folder

`06_Data_Engineering`

Database

`DataEngineeringPracticeDB_Lite`

Repository

`sql-server-learning-journey`

After saving the final query, run these commands in PowerShell from your repository root:

```
git add "06_Data_Engineering/task-063-order-payment-exception-detection.sql"
git commit -m "Complete task 063 order payment exception detection"
git push origin main
```

These commands have not been executed.

## 7. Final assessment

SQL implementation

## 8/10

Assessment of this task only, not your overall SQL proficiency.

Your solution demonstrates good use of CTEs, joins, aggregation, `COALESCE`, and priority-based business rules. The main remaining improvement is to validate the complete result set systematically rather than relying only on selected rows.

Task 063 status: Query review complete; output validation requires one final check of the row count and missing order `1037`. The final Git commit and push remain your responsibility.
*/