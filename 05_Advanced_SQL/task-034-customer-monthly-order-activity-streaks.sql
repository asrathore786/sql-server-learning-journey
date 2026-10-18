/*

## Task 034 — Customer Monthly Order Activity Streaks

Suggested filename: `task-034-customer-monthly-order-activity-streaks.sql`

Save folder: `05_Advanced_SQL`

Database: `PracticeDatabase` — SQL Server 2022

### Business requirement

The customer analytics team wants to identify customers who placed orders in at least three consecutive calendar months.

Return every customer and each qualifying streak of three or more consecutive months. A customer with orders in January, February, March, and April should have one four-month streak, not two overlapping three-month streaks.

A missing calendar month breaks the streak. Multiple orders within one month count as activity in that month, not as separate months.

### Expected output

Return these columns in this order:

| Column                    | Description                                  |
| ------------------------- | -------------------------------------------- |
| `CustomerID`              | Customer identifier                          |
| `CustomerName`            | Customer name                                |
| `StreakStartMonth`        | First month in the streak                    |
| `StreakEndMonth`          | Last month in the streak                     |
| `ConsecutiveMonths`       | Number of consecutive active months          |
| `TotalOrdersDuringStreak` | Total orders across all months in the streak |

Sort by `CustomerID` ascending, then `StreakStartMonth` ascending.

### Rules

- Use `PracticeDatabase` tables `Customers` and `Orders`.
- Count orders of all statuses.
- Exclude customers whose longest streak is shorter than three months.
- Do not hardcode customer IDs or specific dates.
- Aggregate to one row per customer per calendar month before identifying streaks.
- Use CTEs and window functions where appropriate.
- SQL Server 2022 syntax is available, including `DATETRUNC()`.

1. Find the customer first active month
2. Find the same cusotomer in 2nd active month and so on.. if the customer month is missing between the consicutive month then in result we consider only first and Last month where the streak was ended.
3. Streak should be of at least 3 consicutive month
4. We need to calculate the total steak order count in result
5. Customer result should be in order with `CustomerID` ascending, then `StreakStartMonth` ascending.

*/

WITH CTE_MonthlyActivity AS
(
SELECT
	C.CustomerID,
	C.CustomerName,
	DATETRUNC(MONTH,O.OrderDate) AS StartMonth,
    COUNT(O.orderID) AS StartMonthCount
FROM Customers C
INNER JOIN Orders O
	ON O.CustomerID = C.CustomerID
GROUP BY
	C.CustomerID,
	C.CustomerName,
	DATETRUNC(MONTH,O.OrderDate)
)
,
ContinueStreakCheck AS
(
SELECT 
	C.CustomerID,
	C.CustomerName,
    C.StartMonth,
    C.StartMonthCount,
    DATEDIFF(MONTH,CONVERT(DATE, '20250101'),C.StartMonth) - ROW_NUMBER() OVER(PARTITION BY C.customerID ORDER BY C.StartMonth) AS SharedGroup
FROM CTE_MonthlyActivity C
)

SELECT 
	C.CustomerID,
	C.CustomerName,
	MIN(C.StartMonth) AS StreakStartMonth,
	MAX(C.StartMonth) AS StreakEndMonth,
    COUNT(*) AS ConsecutiveMonths,
    SUM(C.StartMonthCount) AS TotalOrdersDuringStreak
FROM ContinueStreakCheck C
GROUP BY 
    C.CustomerID,
	C.CustomerName,
    C.sharedGroup
HAVING COUNT(*) >= 3
ORDER BY C.CustomerID ASC, MIN(C.StartMonth) ASC 

/*

# Task 034 — Customer Monthly Order Activity Streaks

Completed

Advanced SQL

SQL Server 2022

Your query has passed the logical review, and you've provided the output from SSMS. Below is the complete task record for your learning repository.

## 1. Final validated SQL query

Filename: `task-034-customer-monthly-order-activity-streaks.sql`

```

-- Task 034: Customer Monthly Order Activity Streaks
-- Objective:
-- Identify customer activity streaks of at least three
-- consecutive calendar months and calculate total orders
-- during each streak.

WITH CTE_MonthlyActivity AS
(
    SELECT
        C.CustomerID,
        C.CustomerName,
        DATETRUNC(MONTH, O.OrderDate) AS StartMonth,
        COUNT(O.OrderID) AS StartMonthCount
    FROM Customers C
    INNER JOIN Orders O
        ON O.CustomerID = C.CustomerID
    GROUP BY
        C.CustomerID,
        C.CustomerName,
        DATETRUNC(MONTH, O.OrderDate)
),
ContinueStreakCheck AS
(
    SELECT
        C.CustomerID,
        C.CustomerName,
        C.StartMonth,
        C.StartMonthCount,
        DATEDIFF(
            MONTH,
            CONVERT(DATE, '20250101'),
            C.StartMonth
        )
        - ROW_NUMBER() OVER
        (
            PARTITION BY C.CustomerID
            ORDER BY C.StartMonth
        ) AS SharedGroup
    FROM CTE_MonthlyActivity C
)
SELECT
    C.CustomerID,
    C.CustomerName,
    MIN(C.StartMonth) AS StreakStartMonth,
    MAX(C.StartMonth) AS StreakEndMonth,
    COUNT(*) AS ConsecutiveMonths,
    SUM(C.StartMonthCount) AS TotalOrdersDuringStreak
FROM ContinueStreakCheck C
GROUP BY
    C.CustomerID,
    C.CustomerName,
    C.SharedGroup
HAVING COUNT(*) >= 3
ORDER BY
    C.CustomerID ASC,
    MIN(C.StartMonth) ASC;

```

## 2. Your actual output

Five qualifying streaks returned by your SSMS execution.

| CustomerID | CustomerName | StreakStartMonth | StreakEndMonth | ConsecutiveMonths | TotalOrdersDuringStreak |
| ---------- | ------------ | ---------------- | -------------- | ----------------- | ----------------------- |
| 1          | Amit         | 2026-01-01       | 2026-03-01     | 3                 | 5                       |
| 2          | Priya        | 2026-01-01       | 2026-05-01     | 5                 | 6                       |
| 6          | Karan        | 2026-01-01       | 2026-04-01     | 4                 | 5                       |
| 8          | Arjun        | 2026-02-01       | 2026-05-01     | 4                 | 4                       |
| 14         | Varun        | 2026-01-01       | 2026-05-01     | 5                 | 5                       |

## 3. Concept-by-concept review

| Concept                               | What you learned                                                                   |
| ------------------------------------- | ---------------------------------------------------------------------------------- |
| `DATETRUNC(MONTH, OrderDate)`         | Normalize order dates to calendar months.                                          |
| `GROUP BY`                            | Produce one row per customer per active month.                                     |
| `ROW_NUMBER()`                        | Sequence each customer's active months independently.                              |
| `DATEDIFF(MONTH, anchor, StartMonth)` | Convert calendar months into sequential numeric values.                            |
| Gaps and Islands                      | Subtract the row number from the month sequence to identify uninterrupted streaks. |
| `MIN()` and `MAX()`                   | Find each streak's starting and ending month.                                      |
| `COUNT(*)`                            | Count the active months in each streak.                                            |
| `SUM()`                               | Calculate total orders across the streak.                                          |
| `HAVING COUNT(*) >= 3`                | Exclude streaks shorter than three months.                                         |

### The most important concept: Gaps and Islands

Your central expression was:

```
DATEDIFF(MONTH, CONVERT(DATE, '20250101'), C.StartMonth)
- ROW_NUMBER() OVER (
    PARTITION BY C.CustomerID
    ORDER BY C.StartMonth
) AS SharedGroup
```

For consecutive active months, the calendar-month sequence and row number both increase by one. Their difference stays constant. When a month is missing, the difference changes, creating a new streak group.

This pattern is useful for consecutive transaction days, customer retention, payment activity, and operational monitoring.

## 4. Mistakes and improvements from your attempts

You made several useful corrections during this task:

- Initially, you grouped only by customer. That combined separate streaks into one. The solution groups by customer and `SharedGroup`.
- You initially counted consecutive transitions rather than months. A three-month streak has two transitions, but `COUNT(*)` on the monthly rows correctly returns three.
- You initially tried using `LEAD()` to detect gaps. That can identify adjacent active months, but assigning a group identifier makes streak aggregation more straightforward.
- You learned to use `ROW_NUMBER()` and `DATEDIFF()` together. This is the key technique that unlocked the solution.

One technical note: the fixed anchor date `2025-01-01` is arbitrary. Using another fixed date would shift the numeric group identifiers without changing the streak boundaries.

## 5. Validation checklist

- Monthly aggregation implemented.
- Streak groups identified.
- Streak start and end dates calculated.
- Consecutive month count calculated.
- Total orders calculated.
- Streaks shorter than three months excluded.
- Output sorted by `CustomerID` and `StreakStartMonth`.
- SSMS output provided.

## 6. Save and push to GitHub

Save the query in:

`05_Advanced_SQL/task-034-customer-monthly-order-activity-streaks.sql`

Then run these commands in PowerShell from your repository directory:

```
git add "05_Advanced_SQL/task-034-customer-monthly-order-activity-streaks.sql"

git commit -m "Add task 034 customer monthly activity streaks"

git push origin main
```

If Git reports that there is nothing to commit, check whether the file was saved in the correct repository and whether it has already been committed.

## 7. Your progress record

Task 034: Gaps and Islands

Advanced SQL · Customer activity analysis

Skills demonstrated

- Monthly aggregation and analytical window functions.
- Consecutive-sequence detection.
- Group-level aggregation and filtering.
- Translating a business requirement into SQL logic.

  Completion is based on your submitted query and SSMS output. GitHub commit/push is not yet confirmed.

Next task: Task 035 will build on this work with a different analytical problem, rather than simply repeating the same streak calculation.

*/
