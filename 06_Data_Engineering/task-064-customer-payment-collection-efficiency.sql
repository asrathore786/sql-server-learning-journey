/*

## Task 064 — Customer Payment Collection Efficiency

## SQL Practice Task

Advanced

Database: `DataEngineeringPracticeDB_Lite`

Folder: `06_Data_Engineering`

Filename: `task-064-customer-payment-collection-efficiency.sql`

&#x20; Copy filename

### Business requirement

The Finance team wants to assess how effectively the business collects payments from customers during calendar year 2026.

Write a SQL query that returns one row per customer, including customers who placed no orders during 2026.

For each customer, calculate:

| Column                    | Requirement                                                               |
| ------------------------- | ------------------------------------------------------------------------- |
| `CustomerID`              | Customer identifier                                                       |
| `CustomerName`            | Customer name                                                             |
| `TotalOrders`             | Number of orders placed during 2026                                       |
| `TotalOrderValue`         | Sum of `Orders.TotalAmount` for qualifying orders                         |
| `SuccessfulPaymentAmount` | Sum of successful payments linked to qualifying orders                    |
| `CollectionRatePct`       | Successful payment amount divided by total order value, multiplied by 100 |
| `UncollectedAmount`       | Total order value minus successful payment amount                         |
| `CollectionStatus`        | Classification based on the rules below                                   |

### Business rules

1. Include all customers, even if they have no qualifying orders.
2. Only include orders with `OrderDate >= '20260101'` and `OrderDate < '20270101'`.
3. Count each order once, regardless of how many payment records it has.
4. Count only payments with `PaymentStatus = 'Success'` toward the collected amount. Failed and pending payments must not contribute.
5. If no orders exist, `TotalOrders`, `TotalOrderValue`, `SuccessfulPaymentAmount`, and `UncollectedAmount` should return zero.
6. If `TotalOrderValue` is zero, `CollectionRatePct` must be `NULL` to avoid division by zero.
7. Calculate the collection rate using the unrounded amounts, then display it to two decimal places.

Use these classifications in `CollectionStatus`:

| Condition                                                       | Classification        |
| --------------------------------------------------------------- | --------------------- |
| No qualifying orders                                            | `No Orders`           |
| Order value is zero                                             | `Zero Order Value`    |
| Successful payments exceed order value                          | `Overcollected`       |
| Successful payments equal order value                           | `Fully Collected`     |
| Successful payments are greater than zero but below order value | `Partially Collected` |
| No successful payments against a positive order value           | `Not Collected`       |

Sort the result by `CustomerID` ascending.

### Expected output

Your result should have these eight columns, in this order:

`CustomerID`, `CustomerName`, `TotalOrders`, `TotalOrderValue`, `SuccessfulPaymentAmount`, `CollectionRatePct`, `UncollectedAmount`, `CollectionStatus`.

The output must contain one row per customer. Use `DataEngineeringPracticeDB_Lite` and validate the results in SQL Server Management Studio.

Submit your SQL query when ready. I’ll review your attempt first without revealing the solution.

*/



WITH QualifyingOrders AS
(
SELECT 
	C.CustomerID,
	C.CustomerName,
	COUNT(O.OrderID) AS TotalOrders,
	SUM(O.TotalAmount) AS TotalValueOrder
FROM Customers C
LEFT JOIN Orders O
	ON C.CustomerID = O.CustomerID
	AND O.OrderDate  >= '20260101' AND O.OrderDate < '20270101'
GROUP BY
	C.CustomerID,
	C.CustomerName
),
PaymentStatus AS
(
SELECT 
	O.CustomerID,
	SUM(P.paymentAmount) AS SuccessfulPaymentAmount
FROM Orders O
LEFT JOIN Payments P
	ON P.OrderID = O.OrderID
	AND P.PaymentStatus = 'Success'
WHERE O.OrderDate  >= '20260101' AND O.OrderDate < '20270101'
GROUP BY 
	O.CustomerID
)

SELECT 
	Q.CustomerID,
	Q.CustomerName,
	Q.TotalOrders,
	COALESCE(Q.TotalValueOrder,0)  AS TotalValueOrder,
	COALESCE(P.SuccessfulPaymentAmount,0) AS SuccessfulPaymentAmount,
	CAST(COALESCE(P.SuccessfulPaymentAmount,0) * 100.0 / NULLIF(Q.TotalValueOrder,0) AS DECIMAL(10,2)) AS CollectionRatePct,
	COALESCE(Q.TotalValueOrder,0) - COALESCE(P.SuccessfulPaymentAmount,0) AS UncollectedAmount,
	CASE
		WHEN Q.TotalOrders = 0 THEN 'No Orders'
		WHEN Q.TotalValueOrder = 0 THEN 'Zero Order Value'
		WHEN COALESCE(P.SuccessfulPaymentAmount,0) > Q.TotalValueOrder THEN 'Overcollected'
		WHEN COALESCE(P.SuccessfulPaymentAmount,0) = Q.TotalValueOrder THEN 'Fully Collected'		
		WHEN COALESCE(P.SuccessfulPaymentAmount,0) > 0 AND COALESCE(P.SuccessfulPaymentAmount,0) < Q.TotalValueOrder THEN 'Partially Collected'
		WHEN Q.TotalValueOrder > 0 AND COALESCE(P.SuccessfulPaymentAmount,0) = 0 THEN 'Not Collected'
	END	AS CollectionStatus
FROM QualifyingOrders Q
LEFT JOIN PaymentStatus P
	ON Q.CustomerID = P.CustomerID
ORDER BY Q.CustomerID ASC

/*

# Task 064 — Customer Payment Collection Efficiency

## Task completion review

Core logic verified

Database: `DataEngineeringPracticeDB_Lite`

Filename: `task-064-customer-payment-collection-efficiency.sql`

Folder: `06_Data_Engineering`

Overall assessment: Your revised query correctly restricts the payment summary to 2026 orders, uses decimal arithmetic for the collection rate, and returns one row for each of the 20 customers in your supplied output. The main business-rule classifications shown are consistent with the results.

## 1. What you got right

- Customer coverage: Starting from `Customers` with a `LEFT JOIN` preserves customers who have no qualifying orders.
- Date filtering: Both summaries now use the correct 2026 date range: `>= '20260101' AND < '20270101'`.
- Payment aggregation: Successful payments are summed separately at customer level and are restricted to qualifying orders.
- Order counting: `COUNT(O.OrderID)` correctly avoids counting the NULL placeholder row for a customer with no qualifying orders.
- Collection rate: Multiplying by `100.0` makes decimal arithmetic explicit, and `NULLIF` prevents division by zero.
- Classification priority: Your `CASE` expression checks no orders and zero order value before collection outcomes, then distinguishes overcollection, full collection, partial collection, and no collection.
- Missing amounts: `COALESCE` ensures missing payment and order totals are displayed as zero where required.

## 2. Important cases verified in your output

| Customer     | Scenario                                | Expected status       | Result  |
| ------------ | --------------------------------------- | --------------------- | ------- |
| Aarav Sharma | Partially collected                     | `Partially Collected` | Correct |
| Vihaan Rao   | Partially collected, 98.36%             | `Partially Collected` | Correct |
| Sara Khan    | Fully collected                         | `Fully Collected`     | Correct |
| Meera Joshi  | Orders exist, total order value is zero | `Zero Order Value`    | Correct |
| Noor Ali     | No qualifying orders                    | `No Orders`           | Correct |
| Neil Kapoor  | Fully collected                         | `Fully Collected`     | Correct |

The supplied output contains 20 customers. It shows partial collection, full collection, zero order value, and no qualifying orders.

## 3. Validation gaps and improvements

Your output does not demonstrate every classification in the business requirement.

| Scenario              | Validation status |
| --------------------- | ----------------- |
| `No Orders`           | Verified          |
| `Zero Order Value`    | Verified          |
| `Fully Collected`     | Verified          |
| `Partially Collected` | Verified          |
| `Not Collected`       | Not demonstrated  |
| `Overcollected`       | Not demonstrated  |

The query logic includes the two unverified classifications, but those cases should not be claimed as empirically tested without matching output rows.

One additional check: the output shows zero uncollected amounts for fully collected customers and positive uncollected amounts for partially collected customers. Those results are consistent with the intended calculation.

## 4. Final reviewed query

Your latest query is logically correct for the stated requirements. Here is the final version with consistent aliases and formatting.

```

WITH QualifyingOrders AS
(
    SELECT
        C.CustomerID,
        C.CustomerName,
        COUNT(O.OrderID) AS TotalOrders,
        SUM(O.TotalAmount) AS TotalValueOrder
    FROM dbo.Customers AS C
    LEFT JOIN dbo.Orders AS O
        ON O.CustomerID = C.CustomerID
       AND O.OrderDate >= '20260101'
       AND O.OrderDate <  '20270101'
    GROUP BY
        C.CustomerID,
        C.CustomerName
),
PaymentStatus AS
(
    SELECT
        O.CustomerID,
        SUM(P.PaymentAmount) AS SuccessfulPaymentAmount
    FROM dbo.Orders AS O
    LEFT JOIN dbo.Payments AS P
        ON P.OrderID = O.OrderID
       AND P.PaymentStatus = 'Success'
    WHERE O.OrderDate >= '20260101'
      AND O.OrderDate <  '20270101'
    GROUP BY
        O.CustomerID
)
SELECT
    Q.CustomerID,
    Q.CustomerName,
    Q.TotalOrders,
    COALESCE(Q.TotalValueOrder, 0) AS TotalOrderValue,
    COALESCE(P.SuccessfulPaymentAmount, 0)
        AS SuccessfulPaymentAmount,
    CAST(
        COALESCE(P.SuccessfulPaymentAmount, 0) * 100.0
        / NULLIF(Q.TotalValueOrder, 0)
        AS DECIMAL(10, 2)
    ) AS CollectionRatePct,
    COALESCE(Q.TotalValueOrder, 0)
        - COALESCE(P.SuccessfulPaymentAmount, 0)
        AS UncollectedAmount,
    CASE
        WHEN Q.TotalOrders = 0
            THEN 'No Orders'
        WHEN Q.TotalValueOrder = 0
            THEN 'Zero Order Value'
        WHEN COALESCE(P.SuccessfulPaymentAmount, 0)
             > Q.TotalValueOrder
            THEN 'Overcollected'
        WHEN COALESCE(P.SuccessfulPaymentAmount, 0)
             = Q.TotalValueOrder
            THEN 'Fully Collected'
        WHEN COALESCE(P.SuccessfulPaymentAmount, 0) > 0
            THEN 'Partially Collected'
        ELSE 'Not Collected'
    END AS CollectionStatus
FROM QualifyingOrders AS Q
LEFT JOIN PaymentStatus AS P
    ON P.CustomerID = Q.CustomerID
ORDER BY
    Q.CustomerID ASC;

```

The simplified final `CASE` is equivalent for the specified rules because the preceding conditions establish that the remaining positive-order-value cases are either partially collected or not collected.

## 5. Learning log

| Area                     | Learning                                                                                                                                              |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| Join filtering           | A date condition in `ON` does not filter out rows from the left-side table. Use `WHERE` when the qualifying order rows themselves must be restricted. |
| Aggregation grain        | Summarize orders and successful payments at customer level before combining the results.                                                              |
| `COUNT` with `LEFT JOIN` | `COUNT(O.OrderID)` returns zero for customers without qualifying orders; `COUNT(*)` would count the preserved customer row.                           |
| Decimal arithmetic       | Use `100.0` to make decimal arithmetic explicit when calculating percentages.                                                                         |
| Classification priority  | Check `No Orders` and `Zero Order Value` before payment outcomes.                                                                                     |
| Validation discipline    | A classification appearing in the SQL does not prove the test dataset contains that scenario.                                                         |

Correction points / learning log

- Your initial payment summary placed the date condition inside the `LEFT JOIN` without filtering the order rows themselves. Moving the date condition to `WHERE` corrected this issue.
- You changed the percentage multiplier from `100` to `100.0`, making the intended decimal arithmetic explicit.
- No further logical correction is apparent in the latest query. The `Not Collected` and `Overcollected` cases remain unverified in the supplied output.

## 6. Save the task

Filename

`task-064-customer-payment-collection-efficiency.sql`

&#x20; Copy filename

Folder

`06_Data_Engineering`

Database

`DataEngineeringPracticeDB_Lite`

From your repository root in PowerShell, run:

```
git add "06_Data_Engineering/task-064-customer-payment-collection-efficiency.sql"
git commit -m "Complete task 064 customer payment collection efficiency"
git push origin main
```

These commands have not been executed.

## 7. Final assessment

Task-specific SQL rating

# 8.5/10

This rating assesses Task 064, not your overall SQL proficiency.

Your final query demonstrates sound CTE design, aggregation, join handling, date filtering, NULL handling, and business-rule classification. The main remaining gap is test coverage for the `Not Collected` and `Overcollected` outcomes.

Task 064 status: Core query review complete. The supplied output supports the classifications shown, but two status categories still need test data to confirm them empirically.

# Task 064 — Final Assessment (Updated)

## Final task rating

# 9/10

Task logic and test scenarios reviewed

Your revised query addresses the date-filtering issue, uses appropriate aggregation and NULL handling, and implements all six required customer-level classifications. Your additional test results also confirm the `Not Collected` and `Overcollected` scenarios at order level.

This rating applies to Task 064, not your overall SQL proficiency.

## 1. Final validation summary

| Classification        | Validation result           |
| --------------------- | --------------------------- |
| `No Orders`           | Verified in customer output |
| `Zero Order Value`    | Verified in customer output |
| `Fully Collected`     | Verified in customer output |
| `Partially Collected` | Verified in customer output |
| `Not Collected`       | Verified with order 9201    |
| `Overcollected`       | Verified with order 9202    |

Important qualification: The last two classifications were verified at order level, not as customer-level outcomes in the original Task 064 output. The customer-level query logic supports both classifications, but their actual appearance in the customer-level output has not been demonstrated.

## 2. What you demonstrated

- CTEs to separate order aggregation from payment aggregation.
- `LEFT JOIN` behavior to retain customers with no qualifying orders.
- Correct calendar-year filtering using an inclusive start and exclusive end date.
- Aggregation at the customer level to avoid multiplying order values by payment records.
- `COALESCE` and `NULLIF` for missing values and division-by-zero protection.
- `CASE` expressions that prioritize business rules correctly.
- Test-data creation and validation against expected results.

## 3. Learning log

The most important lesson from this task is that the level of aggregation must match the level of the business requirement. An order can be overcollected while its customer remains partially collected overall. Validating both levels prevents incorrect conclusions.

Your main correction was moving the qualifying date condition into the `WHERE` clause of the payment-summary CTE. You also changed the percentage multiplier to `100.0` to make decimal arithmetic explicit.

Correction points: No further query correction is currently identified. Customer-level test coverage for `Not Collected` and `Overcollected` remains a possible improvement.

## 4. Save and commit

Filename

`task-064-customer-payment-collection-efficiency.sql`

Folder

`06_Data_Engineering`

Database

`DataEngineeringPracticeDB_Lite`

Run these commands from your repository root in PowerShell after saving the final query:

```
git add "06_Data_Engineering/task-064-customer-payment-collection-efficiency.sql"
git commit -m "Complete task 064 customer payment collection efficiency"
git push origin main
```

The commands have not been executed.

Final status: Task 064 is complete at the query-review level, with all six required classification rules covered and the two remaining scenarios tested at order level. The outstanding improvement is to demonstrate those two classifications in customer-level results.

*/