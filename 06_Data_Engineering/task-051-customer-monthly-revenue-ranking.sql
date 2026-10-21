/*

## Task 051 — Customer Monthly Revenue Ranking

## Rank Customers by Monthly Revenue

SQL Server 2022 · DataEngineeringPracticeDB_Lite

Filename: `task-051-customer-monthly-revenue-ranking.sql`

Save folder: `06_Data_Engineering`

### Business requirement

The sales analytics team wants to identify the top three customers by revenue for each calendar month.

Using `dbo.Orders`, calculate each customer's total order revenue per month, then rank customers within each month.

Your query must return exactly these columns:

| Column           | Meaning                                              |
| ---------------- | ---------------------------------------------------- |
| `OrderMonth`     | First day of the calendar month                      |
| `CustomerID`     | Customer identifier                                  |
| `MonthlyRevenue` | Total order value for that customer during the month |
| `MonthlyRank`    | Revenue ranking within that month                    |

### Business rules

1. Aggregate orders to one row per customer per calendar month.
2. Use `TotalAmount` from `dbo.Orders` as the revenue measure.
3. Rank customers separately within each month, with the highest revenue ranked first.
4. If two customers have the same revenue, use `CustomerID ASC` as the tie-breaker.
5. Return only the top three customers per month.
6. Sort the final output by `OrderMonth ASC`, then `MonthlyRank ASC`.
7. Use a CTE and a window function. Do not create permanent objects, use temporary tables, or modify source data.

### Your task

Write and run the query independently in SSMS.

Keep the grain in mind: one row per customer per month before ranking. Use `GROUP BY` to calculate monthly revenue, then apply `ROW_NUMBER()` to rank customers within each month.

Share your SQL attempt first. I'll review your logic before providing a solution.

*/



WITH MonthlyRevenue AS
(
SELECT 
	O.CustomerID,
	DATETRUNC(MONTH,O.OrderDate) AS OrderMonth,
	SUM(O.TotalAmount) MonthlyRevenue
FROM Orders O
GROUP BY
	O.CustomerID,
	DATETRUNC(MONTH,O.OrderDate)
),
Ranking AS
(
SELECT 
	M.CustomerID,
	M.OrderMonth,
	M.MonthlyRevenue,
	ROW_NUMBER() OVER(PARTITION BY M.OrderMonth ORDER BY M.MonthlyRevenue DESC, M.CustomerID ASC) AS MonthlyRank
FROM MonthlyRevenue M
)
SELECT 
	R.OrderMonth,
	R.CustomerID,
	R.MonthlyRevenue,
	R.MonthlyRank
FROM Ranking R
WHERE R.MonthlyRank IN (1,2,3)
ORDER BY 
	R.OrderMonth ASC,
	R.MonthlyRank ASC

/*

## Task 051 — Result Review

Status:&#x20;

Completed



Your output is consistent with the query logic. It returns the top three customers for each month where at least three customers have orders, and fewer than three where fewer customers have orders.

### What your output confirms

- Monthly aggregation: Revenue is consolidated for each customer and calendar month.
- Ranking: The highest monthly revenue receives rank 1, followed by ranks 2 and 3.
- Ordering: Results are sorted by month and then rank.
- Sparse months: Months without orders do not appear, because the query groups existing order records rather than generating a complete calendar.

For example, in January 2023, Customer 10 ranks first with `103.70`, Customer 9 ranks second with `103.33`, and Customer 8 ranks third with `102.96`.

In October 2026, only Customer 1 appears, with `3200.00`. That is consistent with the supplied output, although I cannot independently verify the full database from the pasted results alone.

### What you learned

1. `GROUP BY` establishes the required grain: one row per customer per month.
2. `ROW_NUMBER()` ranks those aggregated rows within each month.
3. `PARTITION BY OrderMonth` resets the ranking for every month.
4. Filtering on the rank in the outer query lets you select the top three after aggregation and ranking.

### Final validated query

```

USE DataEngineeringPracticeDB_Lite;
GO

WITH MonthlyRevenue AS
(
    SELECT
        O.CustomerID,
        DATETRUNC(MONTH, O.OrderDate) AS OrderMonth,
        SUM(O.TotalAmount) AS MonthlyRevenue
    FROM dbo.Orders AS O
    GROUP BY
        O.CustomerID,
        DATETRUNC(MONTH, O.OrderDate)
),
Ranking AS
(
    SELECT
        M.CustomerID,
        M.OrderMonth,
        M.MonthlyRevenue,
        ROW_NUMBER() OVER
        (
            PARTITION BY M.OrderMonth
            ORDER BY M.MonthlyRevenue DESC, M.CustomerID ASC
        ) AS MonthlyRank
    FROM MonthlyRevenue AS M
)
SELECT
    R.OrderMonth,
    R.CustomerID,
    R.MonthlyRevenue,
    R.MonthlyRank
FROM Ranking AS R
WHERE R.MonthlyRank <= 3
ORDER BY
    R.OrderMonth ASC,
    R.MonthlyRank ASC;

```

### Git record

Filename: `task-051-customer-monthly-revenue-ranking.sql`

Folder: `06_Data_Engineering`

After saving the query, run:

```
git add 06_Data_Engineering/task-051-customer-monthly-revenue-ranking.sql
git commit -m "Complete task 051: monthly customer revenue ranking"
git push origin main
```

These commands are provided for you to run; I have not verified a commit or push.

Task 051 is complete.

*/