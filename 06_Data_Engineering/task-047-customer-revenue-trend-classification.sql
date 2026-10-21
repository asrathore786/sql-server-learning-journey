/*

## Task 047 — Customer Revenue Trend Classification

Difficulty: Intermediate · `LAG()` · Conditional logic · Time-series analysis

Filename: `task-047-customer-revenue-trend-classification.sql` Folder: `06_Data_Engineering` Database: `DataEngineeringPracticeDB_Lite` Source table: `dbo.Orders`

### Business requirement

The finance team wants to classify each customer's monthly revenue trend by comparing revenue in the current active month with revenue in the previous active month.

Write a SQL query that returns exactly these six columns:

| Column                       | Description                                                   |
| ---------------------------- | ------------------------------------------------------------- |
| `CustomerID`                 | Customer identifier                                           |
| `OrderMonth`                 | First day of the month                                        |
| `MonthlyRevenue`             | Total order value for that customer and month                 |
| `PreviousActiveMonthRevenue` | Revenue in the customer's previous month containing orders    |
| `RevenueChange`              | Current monthly revenue minus previous active month's revenue |
| `RevenueTrend`               | Classification of the revenue movement                        |

### Classification rules

- `No Previous Month` — the customer has no earlier active month.
- `Increased` — current monthly revenue is greater than previous active month's revenue.
- `Decreased` — current monthly revenue is less than previous active month's revenue.
- `Unchanged` — current monthly revenue equals previous active month's revenue.

### Constraints

1. Aggregate orders to one row per customer per active calendar month.
2. Use `LAG()` to retrieve the previous active month's revenue.
3. Do not generate missing calendar months. This task intentionally compares active months, even when calendar gaps exist.
4. Use `CASE` to classify the revenue trend.
5. Calculate `RevenueChange` as current revenue minus previous active month's revenue. Return `NULL` when no previous active month exists.
6. Sort by `CustomerID ASC`, then `OrderMonth ASC`.
7. Read-only query. CTEs and window functions are allowed; no temporary tables or new database objects.

Your task is to translate the business rules into SQL independently. Submit your first attempt, and I’ll review it without giving away the solution.

*/

WITH Monthly_Revenue AS
(
SELECT 
	O.customerID,
	DATETRUNC(MONTH,O.OrderDate) AS ActivityMonth,
	SUM(O.TotalAmount) AS MonthlyRevenue
FROM Orders O
GROUP BY
	O.customerID,
	DATETRUNC(MONTH,O.OrderDate)
),

PreviousDetails AS
(
SELECT
	M.customerID,
	M.ActivityMonth,
	M.MonthlyRevenue,
	LAG(M.ActivityMonth) OVER(PARTITION BY M.CustomerID ORDER BY M.ActivityMonth) AS PreviousMonth,
	LAG(M.MonthlyRevenue) OVER(PARTITION BY M.CustomerID ORDER BY M.ActivityMonth) AS PreviousMonthRevenue
FROM Monthly_Revenue M
)

SELECT 
	P.CustomerID,
	P.ActivityMonth AS OrderMonth,
	P.MonthlyRevenue,
	P.PreviousMonthRevenue,
	P.MonthlyRevenue - P.PreviousMonthRevenue AS RevenueChange,
	CASE
		WHEN P.PreviousMonthRevenue IS NULL THEN 'No Previous Month'
		WHEN P.MonthlyRevenue > P.PreviousMonthRevenue THEN 'Increased'
		WHEN P.MonthlyRevenue < P.PreviousMonthRevenue THEN 'Decreased'
		ELSE 'Unchanged'
	END AS RevenueTrend
FROM PreviousDetails P
ORDER BY 
	P.CustomerID ASC,
	P.ActivityMonth ASC

/*

## Task 047 — Validation result

Status: Passed. ✅ Your query output matches the business requirements for customer revenue trend classification.

### Validation checks

| Check                                                         | Result |
| ------------------------------------------------------------- | ------ |
| One row per customer per active month                         | ✅      |
| Previous active month's revenue calculated using `LAG()`      | ✅      |
| Missing calendar months not generated                         | ✅      |
| Revenue change calculated correctly                           | ✅      |
| First active month classified as `No Previous Month`          | ✅      |
| Increased, Decreased, and Unchanged classifications supported | ✅      |
| Output sorted by customer and month                           | ✅      |

### Example validation: Customer 1

- February 2023: ₹655.37 − ₹100.37 = ₹555.00 → `Increased`
- August 2023: ₹530.37 − ₹2,875.37 = −₹2,345.00 → `Decreased`
- May 2024: ₹285.37 − ₹530.37 = −₹245.00 → `Decreased`

These calculations are correct. Notice that May 2024 is compared with August 2023, the previous active month—not April 2024, when the customer had no orders. That is exactly what this task specifies.

## Final task record

Filename: `task-047-customer-revenue-trend-classification.sql` Folder: `06_Data_Engineering` Database: `DataEngineeringPracticeDB_Lite`

### Final validated query

```

USE DataEngineeringPracticeDB_Lite;
GO

WITH Monthly_Revenue AS
(
    SELECT
        O.CustomerID,
        DATETRUNC(MONTH, O.OrderDate) AS ActivityMonth,
        SUM(O.TotalAmount) AS MonthlyRevenue
    FROM dbo.Orders AS O
    GROUP BY
        O.CustomerID,
        DATETRUNC(MONTH, O.OrderDate)
),
PreviousDetails AS
(
    SELECT
        M.CustomerID,
        M.ActivityMonth,
        M.MonthlyRevenue,
        LAG(M.ActivityMonth) OVER
        (
            PARTITION BY M.CustomerID
            ORDER BY M.ActivityMonth
        ) AS PreviousMonth,
        LAG(M.MonthlyRevenue) OVER
        (
            PARTITION BY M.CustomerID
            ORDER BY M.ActivityMonth
        ) AS PreviousMonthRevenue
    FROM Monthly_Revenue AS M
)
SELECT
    P.CustomerID,
    P.ActivityMonth AS OrderMonth,
    P.MonthlyRevenue,
    P.PreviousMonthRevenue,
    P.MonthlyRevenue - P.PreviousMonthRevenue AS RevenueChange,
    CASE
        WHEN P.PreviousMonth IS NULL THEN 'No Previous Month'
        WHEN P.MonthlyRevenue > P.PreviousMonthRevenue THEN 'Increased'
        WHEN P.MonthlyRevenue < P.PreviousMonthRevenue THEN 'Decreased'
        ELSE 'Unchanged'
    END AS RevenueTrend
FROM PreviousDetails AS P
ORDER BY
    P.CustomerID ASC,
    P.ActivityMonth ASC;

```

### Key concepts demonstrated

- Aggregation grain: one row per customer per month.
- `LAG()`: retrieves the preceding row within each customer's monthly sequence.
- `PARTITION BY`: isolates each customer's calculation.
- `CASE`: converts numerical comparisons into business classifications.
- Active-month versus calendar-month logic: gaps are allowed, so the prior row may represent a much earlier calendar month.

### Git commands

After saving the file, run:

```
git add 06_Data_Engineering/task-047-customer-revenue-trend-classification.sql
git commit -m "Complete task 047: customer revenue trend classification"
git push origin main
```

Task 047 is complete. Git commit and push are not confirmed.
*/
