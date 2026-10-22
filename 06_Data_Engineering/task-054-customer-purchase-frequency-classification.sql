/*

## Task 054 — Customer Purchase Frequency Classification

Difficulty level

High

Database: `DataEngineeringPracticeDB_Lite`

Table: `dbo.Orders`

Filename: `task-054-customer-purchase-frequency-classification.sql`

Folder: `06_Data_Engineering`

### Business requirement

The customer analytics team wants to classify customers based on how frequently they place orders.

Write a SQL query that analyzes each customer's order history and returns exactly these columns:

| Column                      | Description                                     |
| --------------------------- | ----------------------------------------------- |
| `CustomerID`                | Customer identifier                             |
| `TotalOrders`               | Total number of orders placed                   |
| `FirstOrderDate`            | Date of the customer's first order              |
| `LastOrderDate`             | Date of the customer's most recent order        |
| `DaysBetweenFirstAndLast`   | Number of days between the first and last order |
| `PurchaseFrequencyCategory` | Classification based on the rules below         |

### Business rules

Classify each customer using these conditions:

- Single Order: exactly one order.
- High Frequency: more than 10 orders.
- Medium Frequency: 5–10 orders, inclusive.
- Low Frequency: 2–4 orders, inclusive.

Additional requirements:

1. Include every customer who has at least one order.
2. Calculate the first and last order dates from the order history.
3. Return `DaysBetweenFirstAndLast` as the number of calendar-day boundaries between those dates.
4. Sort by `TotalOrders` descending, then `CustomerID` ascending.
5. Use read-only SQL. CTEs and window functions are permitted; do not create temporary or permanent tables.

Your turn: Write the query independently and run it in SSMS. I won't provide hints about grain, SQL functions, or query structure before you attempt it.

*/


WITH Customer_Order_Summary AS
(
SELECT
	O.CustomerID,
	COUNT(O.OrderID) AS TotalOrders,
	MIN(O.orderDate) AS FirstOrderDate,
	MAX(O.orderDate) AS LastOrderDate
FROM Orders O
GROUP BY 
	O.CustomerID
)

SELECT 
	M.CustomerID,
	M.TotalOrders,
	M.FirstOrderDate,
	M.LastOrderDate,
	DATEDIFF(DAY, M.FirstOrderDate,M.LastOrderDate) AS DaysBetweenFirstAndLast,
	CASE
		WHEN M.TotalOrders = 1 THEN 'Single Order'
		WHEN M.TotalOrders BETWEEN 2 AND 4 THEN 'Low Frequency'
		WHEN M.TotalOrders BETWEEN 5 AND 10 THEN 'Medium Frequency'
		WHEN M.TotalOrders > 10 THEN 'High Frequency'
		ELSE 'First Order'
	END AS PurchaseFrequencyCategory
FROM Customer_Order_Summary M
ORDER BY M.TotalOrders DESC, M.CustomerID ASC


/*

## Task 054 — Validation result

Status: Passed — query logic and all 10 supplied test cases are correct. ✅

Your output matches the expected purchase-frequency classifications, date spans, and descending order-count sorting.

| Test case                      | Actual result | Status |
| ------------------------------ | ------------- | ------ |
| 1 order → Single Order         | 0 days        | ✅      |
| 2–4 orders → Low Frequency     | 7–21 days     | ✅      |
| 5–10 orders → Medium Frequency | 28–63 days    | ✅      |
| 11+ orders → High Frequency    | 70–133 days   | ✅      |
| Sort by orders descending      | 20 → 1        | ✅      |

### What you learned

- Aggregation: `COUNT`, `MIN`, and `MAX` produce customer-level order-history summaries.
- Date calculations: `DATEDIFF(DAY, FirstOrderDate, LastOrderDate)` returns the calendar-day boundaries between the dates.
- Business classification: `CASE` translates numeric thresholds into meaningful categories.
- Boundary testing: Testing 4 versus 5 orders and 10 versus 11 orders confirms that the category thresholds are implemented correctly.
- Sorting: `ORDER BY TotalOrders DESC, CustomerID ASC` puts the highest-frequency customers first and resolves ties by customer ID.

One qualification: the output validates the ten controlled test cases, not every possible data condition in the original database. Your classification logic is correct for the stated requirements.

### Final task record

## Task 054 — Customer Purchase Frequency Classification

Difficulty: High · Folder: `06_Data_Engineering`

Filename: `task-054-customer-purchase-frequency-classification.sql`

What was improved: Corrected the date-difference unit from `MONTH` to `DAY` and added the required sorting.

Validation: 10/10 controlled customer scenarios passed.

Original attempt: Your first query used month boundaries and omitted the final sorting. Your revised query corrected both.

### Git commands

Save your final query in the repository folder:

`06_Data_Engineering\task-054-customer-purchase-frequency-classification.sql`

Then run:

```
git add 06_Data_Engineering/task-054-customer-purchase-frequency-classification.sql
git commit -m "Complete task 054 customer purchase frequency classification"
git push origin main
```

These commands are provided for you to execute; I have not performed the commit or push.

Task 054 is complete.

*/