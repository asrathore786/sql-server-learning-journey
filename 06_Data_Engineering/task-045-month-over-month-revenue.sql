/*
## Task 045 — Month-over-Month Revenue Comparison

Filename: `task-045-month-over-month-revenue.sql` Folder: `06_Data_Engineering` Database: `DataEngineeringPracticeDB_Lite`

Business requirement

The finance team wants to compare monthly order revenue with the previous active month for each customer.

Write a query using `dbo.Orders` that returns exactly these columns:

| Column                 | Description                                                   |
| ---------------------- | ------------------------------------------------------------- |
| `CustomerID`           | Customer identifier                                           |
| `OrderMonth`           | First day of the order's month                                |
| `MonthlyRevenue`       | Sum of order amounts for that customer and month              |
| `PreviousMonthRevenue` | Revenue from the previous active month for that customer      |
| `RevenueChange`        | Current monthly revenue minus previous active month's revenue |

Requirements:

1. Aggregate orders to one row per customer per calendar month.
2. Use `LAG()` to retrieve the previous month's revenue.
3. If a customer has no previous active month, `PreviousMonthRevenue` and `RevenueChange` should be `NULL`.
4. If a customer has no orders in an intervening calendar month, compare against their previous active month; do not generate missing months.
5. Sort by `CustomerID ASC`, then `OrderMonth ASC`.
6. Use CTEs and window functions as needed. Do not use temporary tables or create database objects.
7. Read-only query.

Your turn: Write your first attempt. I’ll review your SQL before you execute it.

*/

WITH MONTHLY_REVENUE AS
(
SELECT
	O.CustomerID,
	DATETRUNC(MONTH,O.OrderDate) OrderMonth,
	SUM(O.TotalAmount) AS MonthTotal
FROM Orders O
GROUP BY
	O.CustomerID,
	DATETRUNC(MONTH,O.OrderDate)
),

Revenue AS
(
SELECT 
	MON.CustomerID,
	MON.OrderMonth,
	MON.MonthTotal,
	LAG(MON.MonthTotal) OVER(PARTITION BY MON.CustomerID ORDER BY MON.OrderMonth) AS PreviousMonthTotal
FROM MONTHLY_REVENUE MON
)

SELECT 
	R.CustomerID,
	R.OrderMonth,
	R.MonthTotal AS MonthlyRevenue,
	R.PreviousMonthTotal AS PreviousMonthRevenue,
	R.MonthTotal - R.PreviousMonthTotal AS RevenueChange
FROM Revenue R
ORDER BY 
	R.CustomerID ASC,
	R.OrderMonth ASC

/*

# Task 045 — Final Result Record

# Month-over-Month Revenue Comparison

Status: Complete · Query reviewed · SSMS output validated

## 1. Task details

| Item          | Details                                   |
| ------------- | ----------------------------------------- |
| Task number   | 045                                       |
| Filename      | `task-045-month-over-month-revenue.sql`   |
| Folder        | `06_Data_Engineering`                     |
| Database      | `DataEngineeringPracticeDB_Lite`          |
| Main concepts | CTEs, aggregation, `DATETRUNC()`, `LAG()` |

## 2. Final query

```

USE DataEngineeringPracticeDB_Lite;
GO

WITH MONTHLY_REVENUE AS
(
    SELECT
        O.CustomerID,
        DATETRUNC(MONTH, O.OrderDate) AS OrderMonth,
        SUM(O.TotalAmount) AS MonthTotal
    FROM dbo.Orders AS O
    GROUP BY
        O.CustomerID,
        DATETRUNC(MONTH, O.OrderDate)
),
Revenue AS
(
    SELECT
        M.CustomerID,
        M.OrderMonth,
        M.MonthTotal,
        LAG(M.MonthTotal) OVER
        (
            PARTITION BY M.CustomerID
            ORDER BY M.OrderMonth
        ) AS PreviousMonthTotal
    FROM MONTHLY_REVENUE AS M
)
SELECT
    R.CustomerID,
    R.OrderMonth,
    R.MonthTotal AS MonthlyRevenue,
    R.PreviousMonthTotal AS PreviousMonthRevenue,
    R.MonthTotal - R.PreviousMonthTotal AS RevenueChange
FROM Revenue AS R
ORDER BY
    R.CustomerID ASC,
    R.OrderMonth ASC;

```

## 3. Result validation

Your submitted SSMS output supports these checks:

- Monthly revenue is aggregated by customer and month.
- `LAG()` retrieves the previous active month's revenue for the same customer.
- `RevenueChange` is calculated as current revenue minus previous active-month revenue.
- The first active month has `NULL` for both previous revenue and revenue change.
- Missing calendar months are not generated; the comparison uses the previous available month.
- Results are ordered by customer and month.

Important: This query compares against the previous active month, not necessarily the previous calendar month. That matches Task 045's requirement.

## 4. What you learned

The key skill is separating a multi-stage business requirement into the correct data grains:

1. Monthly grain: Aggregate individual orders to one row per customer per month.
2. Historical comparison: Apply `LAG()` to the monthly result, not the raw orders.
3. Business calculation: Subtract previous monthly revenue from current monthly revenue.
4. Edge case: Preserve `NULL` when no previous active month exists.

This is a useful pattern for revenue analysis, customer activity reporting, and financial time-series comparisons.

## 5. Git commands

After saving the query in the specified folder, run:

```
git add "06_Data_Engineering/task-045-month-over-month-revenue.sql"
git commit -m "Add Task 045 month-over-month revenue analysis"
git push origin main
```

These commands are for you to execute; I have not verified that the file has been committed or pushed.

Task 045 is closed. Task 046 will remain separate until you ask to begin it.
*/

