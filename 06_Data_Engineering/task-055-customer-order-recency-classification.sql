/*

## Task 055 — Customer Order Recency Classification

## Difficulty: Advanced

Task 055

Database: `DataEngineeringPracticeDB_Lite`

Folder: `06_Data_Engineering`

Filename: `task-055-customer-order-recency-classification.sql`

&#x20; Copy filename

### Business requirement

The customer analytics team wants to identify how recently each customer has placed an order. This will help the business distinguish active customers from customers who may be disengaging.

Produce one record per customer who has at least one order in `dbo.Orders`.

Your output must contain these columns:

| Column                    | Business meaning                                                                         |
| ------------------------- | ---------------------------------------------------------------------------------------- |
| `CustomerID`              | Customer identifier                                                                      |
| `TotalOrders`             | Total number of orders in the customer's history                                         |
| `FirstOrderDate`          | Date of the customer's earliest order                                                    |
| `LastOrderDate`           | Date of the customer's most recent order                                                 |
| `DaysSinceLastOrder`      | Number of calendar-day boundaries between the most recent order date and 31 October 2026 |
| `CustomerRecencyCategory` | Customer's recency classification                                                        |

### Business rules

Classify customers using the following thresholds:

- Very Recent: 0–7 days since the last order.
- Recent: 8–30 days.
- At Risk: 31–60 days.
- Dormant: More than 60 days.

Use 31 October 2026 as the fixed reporting date for every customer, regardless of the current system date. Include customers with at least one order, and sort by `DaysSinceLastOrder` ascending, followed by `CustomerID` ascending.

### Constraints

- Use SQL Server 2022 syntax.
- Read-only query: do not create or modify database objects.
- CTEs and window functions are permitted.
- Do not use a hard-coded customer list.
- Follow your usual workflow: save the query under the filename above, attempt it independently, and send me your SQL for review.

No hints or solution provided. Work out the approach yourself, including how to handle the fixed reporting date and category boundaries.

*/

WITH BeforeDateOrders AS
(
SELECT
	*
FROM Orders
WHERE OrderDate <= CAST('20261031' AS DATE)
),
Customer_Order_Summary AS
(
SELECT
	O.CustomerID,
	COUNT(O.OrderID) AS TotalOrders,
	MIN(O.OrderDate) AS FirstOrderDate,
	MAX(O.OrderDate) AS LastOrderDate
FROM BeforeDateOrders O
WHERE O.CustomerID = 1
GROUP BY O.CustomerID
)

SELECT
	C.CustomerID,
	C.TotalOrders,
	C.FirstOrderDate,
	C.LastOrderDate,
	DATEDIFF(DAY,C.LastOrderDate, CAST('20261031' AS DATE)) AS DaysSinceLastOrder,
	CASE
		WHEN DATEDIFF(DAY,C.LastOrderDate, CAST('20261031' AS DATE)) BETWEEN 0 AND 7 THEN 'Very Recent'
		WHEN DATEDIFF(DAY,C.LastOrderDate, CAST('20261031' AS DATE)) BETWEEN 8 AND 30 THEN 'Recent'
		WHEN DATEDIFF(DAY,C.LastOrderDate, CAST('20261031' AS DATE)) BETWEEN 31 AND 60 THEN 'At Risk'
		WHEN DATEDIFF(DAY,C.LastOrderDate, CAST('20261031' AS DATE)) > 60 THEN 'Dormant'
	END AS CustomerRecencyCategory
FROM Customer_Order_Summary C
ORDER BY 
	DaysSinceLastOrder ASC,
	C.CustomerID ASC


/*

Task 055 — Customer Order Recency Classification: Output validated for Customer 1. ✅

Your result is consistent with the business rules:

| Column                  | Observed result | Validation                                     |
| ----------------------- | --------------- | ---------------------------------------------- |
| CustomerID              | 1               | Correct                                        |
| TotalOrders             | 28              | Consistent with eligible orders in your output |
| FirstOrderDate          | 2023-01-01      | Correct format                                 |
| LastOrderDate           | 2026-10-31      | Includes the report date                       |
| DaysSinceLastOrder      | 0               | Correct                                        |
| CustomerRecencyCategory | Very Recent     | Correct                                        |

### What you learned

- Filter before aggregation: future orders must be excluded before calculating the count, minimum date, and maximum date.
- Inclusive date boundaries: `<=` includes orders on the reporting date.
- Recency calculation: `DATEDIFF(DAY, LastOrderDate, ReportDate)` returns `0` when both dates are the same.
- Business classification: the `CASE` expression maps the calculated age into the required categories.

One important qualification: this validates Customer 1's supplied result, not every customer or all category boundaries. A complete check should also confirm the 7/8-day, 30/31-day, and 60/61-day boundaries.

## Task 055 — Final task record

Difficulty: Advanced Filename: `task-055-customer-order-recency-classification.sql` Folder: `06_Data_Engineering` Database: `DataEngineeringPracticeDB_Lite`

### Final validated query

```

WITH BeforeDateOrders AS
(
    SELECT
        OrderID,
        CustomerID,
        OrderDate
    FROM dbo.Orders
    WHERE OrderDate <= CAST('20261031' AS DATE)
),
Customer_Order_Summary AS
(
    SELECT
        O.CustomerID,
        COUNT(O.OrderID) AS TotalOrders,
        MIN(O.OrderDate) AS FirstOrderDate,
        MAX(O.OrderDate) AS LastOrderDate
    FROM BeforeDateOrders O
    GROUP BY O.CustomerID
)
SELECT
    C.CustomerID,
    C.TotalOrders,
    C.FirstOrderDate,
    C.LastOrderDate,
    DATEDIFF(DAY, C.LastOrderDate, CAST('20261031' AS DATE))
        AS DaysSinceLastOrder,
    CASE
        WHEN DATEDIFF(DAY, C.LastOrderDate, CAST('20261031' AS DATE))
             BETWEEN 0 AND 7 THEN 'Very Recent'
        WHEN DATEDIFF(DAY, C.LastOrderDate, CAST('20261031' AS DATE))
             BETWEEN 8 AND 30 THEN 'Recent'
        WHEN DATEDIFF(DAY, C.LastOrderDate, CAST('20261031' AS DATE))
             BETWEEN 31 AND 60 THEN 'At Risk'
        WHEN DATEDIFF(DAY, C.LastOrderDate, CAST('20261031' AS DATE))
             > 60 THEN 'Dormant'
    END AS CustomerRecencyCategory
FROM Customer_Order_Summary C
ORDER BY
    DaysSinceLastOrder ASC,
    C.CustomerID ASC;

```

### Git record

Save the query at:

`06_Data_Engineering\task-055-customer-order-recency-classification.sql`

Then run these commands from your repository root:

```
git add 06_Data_Engineering/task-055-customer-order-recency-classification.sql
git commit -m "Add customer order recency classification task"
git push origin main
```

These commands have not been executed.

Task 055 is complete at the query-logic level, with Customer 1's output checked. The full customer result set and every category boundary have not yet been independently validated.

*/
