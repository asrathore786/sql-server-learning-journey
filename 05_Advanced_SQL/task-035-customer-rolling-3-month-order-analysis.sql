/*

## Task 035 — Customer Rolling 3-Month Order Analysis

Difficulty: Advanced Focus: Window functions, monthly aggregation, rolling calculations, CTEs, and date boundaries.

Save your SQL file first

Filename: `task-035-customer-rolling-3-month-order-analysis.sql`

Folder: `05_Advanced_SQL`

Database: `PracticeDatabase` — SQL Server 2022

### Business requirement

The business wants to identify customers whose order activity is increasing or decreasing over time. Build a report showing each customer's monthly order count alongside their rolling three-calendar-month order total.

For every customer and every month in which they placed an order, calculate the total number of orders during that month and the two preceding calendar months.

For example, if a customer has orders in January and March but none in February, the March rolling total must include January, February, and March. February contributes zero orders; it must not be skipped just because the customer had no activity that month.

### Expected output

Return these columns in this order:

| Column                            | Requirement                                                          |
| --------------------------------- | -------------------------------------------------------------------- |
| `CustomerID`                      | Customer identifier                                                  |
| `CustomerName`                    | Customer name                                                        |
| `ActivityMonth`                   | Month represented as the first day of the month                      |
| `MonthlyOrderCount`               | Orders placed in that month                                          |
| `Rolling3MonthOrderCount`         | Total orders across that month and the preceding two calendar months |
| `PreviousRolling3MonthOrderCount` | The previous month's rolling total                                   |
| `RollingTotalChange`              | Current rolling total minus the previous month's rolling total       |
| `TrendClassification`             | `New Comparison`, `Increased`, `Decreased`, or `Unchanged`           |

### Rules and edge cases

1. Count all orders regardless of `Status`.
2. Return one row per customer per active month. Do not generate rows for months in which the customer placed no orders.
3. Calculate rolling totals over calendar months, not merely the last three rows of activity.
4. A month with no orders contributes zero to the rolling total.
5. Use `New Comparison` when no previous month's rolling total is available for that customer.
6. Otherwise classify the trend by comparing the current rolling total with the previous rolling total.
7. Exclude customers who have never placed an order.
8. Sort by `CustomerID ASC`, then `ActivityMonth ASC`.

Important: The rolling calculation must account for missing calendar months. Simply applying `SUM(MonthlyOrderCount) OVER (... ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)` to active-month rows will produce incorrect results when months are missing.

Your task is to write the query independently. Start with the filename and folder above, save your SQL, and run it in SSMS. Submit your query and output for review. I’ll assess correctness and edge cases before showing any solution or hints.

Approcach Toward the solution:
1. We need to identify the customer rolling 3 months count without skipping the continuation of month , if the month is missing then missing month Order count should be 0 and include in rolling month.
2. Will first identity all the order date corresponding to customer , then will check for 2 consicutive preceeding month if the preceding month is available in customer month then count will be added and if not then the count will be added with 0 but in result we do not need to show the missing monht.
3. Based on the Trend of counts increase or decrease will include the Classification on each month either customer order count increased, decrease or no change, when there is no previous month rolling total is available then we mark that customer as 'NEW Comparision'
4. If customer have not placed any order then these customer must be exclude.
5. Result should be sort by Customer ID ASc and ActivityMonth ASC
*/


-- Task 035: Customer Rolling 3-Month Order Analysis
-- Objective:
-- Calculate each customer's monthly order count, rolling 3-calendar-month
-- order total, previous month's rolling total, change, and trend classification.
-- Missing calendar months contribute zero but are excluded from final output.

-- STEP 1: Aggregate orders into one row per customer per active month
WITH CTE_ActivityMonth AS
(
    SELECT
        C.CustomerID,
        C.CustomerName,

        -- Normalize every order date to the first day of its month.
        -- Example: 2026-01-15 becomes 2026-01-01.
        DATETRUNC(MONTH, O.OrderDate) AS ActivityMonth,

        -- Count all orders placed by this customer during the month.
        COUNT(*) AS MonthlyOrderCount
    FROM Customers C
    INNER JOIN Orders O
        ON O.CustomerID = C.CustomerID

    -- One row per customer per calendar month.
    GROUP BY
        C.CustomerID,
        C.CustomerName,
        DATETRUNC(MONTH, O.OrderDate)
),

-- STEP 2: Determine each customer's calendar generation range
CTE_CustomerRange AS
(
    SELECT
        CustomerID,
        CustomerName,

        -- Start two months before the first active month.
        -- This allows the first active month to have a three-month window.
        DATEADD(MONTH, -2, MIN(ActivityMonth)) AS CalendarStartMonth,

        -- End at the customer's last active month.
        MAX(ActivityMonth) AS CalendarEndMonth
    FROM CTE_ActivityMonth
    GROUP BY
        CustomerID,
        CustomerName
),

-- STEP 3: Generate every calendar month in each customer's date range
Calendar AS
(
    -- Anchor member: start with the first generated calendar month.
    SELECT
        CustomerID,
        CustomerName,
        CalendarStartMonth AS ActivityMonth,
        CalendarEndMonth
    FROM CTE_CustomerRange

    UNION ALL

    -- Recursive member: advance by one month until the end month.
    SELECT
        CustomerID,
        CustomerName,
        DATEADD(MONTH, 1, ActivityMonth) AS ActivityMonth,
        CalendarEndMonth
    FROM Calendar
    WHERE ActivityMonth < CalendarEndMonth
),

-- STEP 4: Match actual monthly counts to the complete calendar
MonthlyCalendar AS
(
    SELECT
        Cal.CustomerID,
        Cal.CustomerName,
        Cal.ActivityMonth,

        -- If no order row exists for a calendar month, treat its count as zero.
        COALESCE(A.MonthlyOrderCount, 0) AS MonthlyOrderCount
    FROM Calendar Cal
    LEFT JOIN CTE_ActivityMonth A
        ON A.CustomerID = Cal.CustomerID
        AND A.ActivityMonth = Cal.ActivityMonth
),

-- STEP 5: Calculate the rolling total for three calendar months
Rolling AS
(
    SELECT
        M.CustomerID,
        M.CustomerName,
        M.ActivityMonth,
        M.MonthlyOrderCount,

        -- Add the current month's orders and the previous two calendar months.
        -- This works because MonthlyCalendar contains every month, including
        -- months with zero orders.
        SUM(M.MonthlyOrderCount) OVER
        (
            PARTITION BY M.CustomerID
            ORDER BY M.ActivityMonth
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS Rolling3MonthOrderCount
    FROM MonthlyCalendar M
),

-- STEP 6: Retrieve the previous calendar month's rolling total
Preview AS
(
    SELECT
        R.CustomerID,
        R.CustomerName,
        R.ActivityMonth,
        R.MonthlyOrderCount,
        R.Rolling3MonthOrderCount,

        -- LAG returns the rolling total from the immediately preceding
        -- calendar row for the same customer.
        LAG(R.Rolling3MonthOrderCount) OVER
        (
            PARTITION BY R.CustomerID
            ORDER BY R.ActivityMonth
        ) AS PreviousRolling3MonthOrderCount
    FROM Rolling R
)

-- STEP 7: Produce the final report and classify the rolling-total trend
SELECT
    P.CustomerID,
    P.CustomerName,
    P.ActivityMonth,
    P.MonthlyOrderCount,
    P.Rolling3MonthOrderCount,
    P.PreviousRolling3MonthOrderCount,

    -- Positive result means the rolling total increased.
    -- Negative result means it decreased.
    -- Zero means it remained unchanged.
    P.Rolling3MonthOrderCount
        - P.PreviousRolling3MonthOrderCount AS RollingTotalChange,

    -- Classify the change by comparing consecutive calendar-month
    -- rolling totals. The first generated month has no previous total.
    CASE
        WHEN P.PreviousRolling3MonthOrderCount IS NULL
            THEN 'New Comparison'
        WHEN P.Rolling3MonthOrderCount
             > P.PreviousRolling3MonthOrderCount
            THEN 'Increased'
        WHEN P.Rolling3MonthOrderCount
             < P.PreviousRolling3MonthOrderCount
            THEN 'Decreased'
        ELSE 'Unchanged'
    END AS TrendClassification
FROM Preview P

-- Remove zero-order months only after calculating rolling totals and LAG.
-- These months still contribute to the calculations above.
WHERE P.MonthlyOrderCount > 0

-- Sort by customer, then chronologically by month.
ORDER BY
    P.CustomerID ASC,
    P.ActivityMonth ASC

-- Permit recursive calendar generation beyond SQL Server's default limit.
OPTION (MAXRECURSION 0);


/*
# Task 035 — Complete SQL Learning Record

## Customer Rolling 3-Month Order Analysis

SQL Server 2022 · PracticeDatabase · Advanced SQL

Assessment

# 9.5/10

Core concepts

# 6

The original query output was supplied from SSMS. The revised query with the extended calendar has not yet been independently confirmed with fresh SSMS output.

## 1. Suggested file and location

- Filename: `task-035-customer-rolling-3-month-order-analysis.sql`
- Folder: `05_Advanced_SQL`
- Full relative path: `05_Advanced_SQL/task-035-customer-rolling-3-month-order-analysis.sql`

## 2. Business requirement

Create a monthly report for every customer who has placed orders. For each active month, calculate the current month's order count, the rolling total across that month and the previous two calendar months, the previous calendar month's rolling total, the difference between rolling totals, and a trend classification.

Missing months must contribute zero to calculations but must not appear in the final report. The output must be sorted by customer ID and activity month.

## 3. Final query with inline comments

```

-- Task 035: Customer Rolling 3-Month Order Analysis
-- SQL Server 2022 | PracticeDatabase

-- STEP 1: Aggregate orders by customer and active calendar month.
WITH CTE_ActivityMonth AS
(
    SELECT
        C.CustomerID,
        C.CustomerName,
        DATETRUNC(MONTH, O.OrderDate) AS ActivityMonth,
        COUNT(*) AS MonthlyOrderCount
    FROM Customers C
    INNER JOIN Orders O
        ON O.CustomerID = C.CustomerID
    GROUP BY
        C.CustomerID,
        C.CustomerName,
        DATETRUNC(MONTH, O.OrderDate)
),

-- STEP 2: Establish the calendar range for each customer.
CTE_CustomerRange AS
(
    SELECT
        CustomerID,
        CustomerName,

        -- Start two months before the first active month,
        -- allowing a complete three-calendar-month window.
        DATEADD(MONTH, -2, MIN(ActivityMonth)) AS CalendarStartMonth,

        MAX(ActivityMonth) AS CalendarEndMonth
    FROM CTE_ActivityMonth
    GROUP BY
        CustomerID,
        CustomerName
),

-- STEP 3: Generate a continuous monthly calendar per customer.
Calendar AS
(
    -- Anchor: begin at the calculated calendar start month.
    SELECT
        CustomerID,
        CustomerName,
        CalendarStartMonth AS ActivityMonth,
        CalendarEndMonth
    FROM CTE_CustomerRange

    UNION ALL

    -- Recursion: add one calendar month until the end month.
    SELECT
        CustomerID,
        CustomerName,
        DATEADD(MONTH, 1, ActivityMonth),
        CalendarEndMonth
    FROM Calendar
    WHERE ActivityMonth < CalendarEndMonth
),

-- STEP 4: Match actual order counts to the calendar.
-- Missing months receive zero orders.
MonthlyCalendar AS
(
    SELECT
        Cal.CustomerID,
        Cal.CustomerName,
        Cal.ActivityMonth,
        COALESCE(A.MonthlyOrderCount, 0) AS MonthlyOrderCount
    FROM Calendar Cal
    LEFT JOIN CTE_ActivityMonth A
        ON A.CustomerID = Cal.CustomerID
        AND A.ActivityMonth = Cal.ActivityMonth
),

-- STEP 5: Calculate the current and previous two calendar months.
Rolling AS
(
    SELECT
        M.CustomerID,
        M.CustomerName,
        M.ActivityMonth,
        M.MonthlyOrderCount,

        SUM(M.MonthlyOrderCount) OVER
        (
            PARTITION BY M.CustomerID
            ORDER BY M.ActivityMonth
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS Rolling3MonthOrderCount
    FROM MonthlyCalendar M
),

-- STEP 6: Retrieve the previous calendar month's rolling total.
Preview AS
(
    SELECT
        R.CustomerID,
        R.CustomerName,
        R.ActivityMonth,
        R.MonthlyOrderCount,
        R.Rolling3MonthOrderCount,

        LAG(R.Rolling3MonthOrderCount) OVER
        (
            PARTITION BY R.CustomerID
            ORDER BY R.ActivityMonth
        ) AS PreviousRolling3MonthOrderCount
    FROM Rolling R
)

-- STEP 7: Calculate the change, classify the trend, and return active months.
SELECT
    P.CustomerID,
    P.CustomerName,
    P.ActivityMonth,
    P.MonthlyOrderCount,
    P.Rolling3MonthOrderCount,
    P.PreviousRolling3MonthOrderCount,

    P.Rolling3MonthOrderCount
        - P.PreviousRolling3MonthOrderCount AS RollingTotalChange,

    CASE
        WHEN P.PreviousRolling3MonthOrderCount IS NULL
            THEN 'New Comparison'
        WHEN P.Rolling3MonthOrderCount
             > P.PreviousRolling3MonthOrderCount
            THEN 'Increased'
        WHEN P.Rolling3MonthOrderCount
             < P.PreviousRolling3MonthOrderCount
            THEN 'Decreased'
        ELSE 'Unchanged'
    END AS TrendClassification
FROM Preview P

-- Filter only after rolling calculations and LAG are complete.
WHERE P.MonthlyOrderCount > 0

ORDER BY
    P.CustomerID ASC,
    P.ActivityMonth ASC

OPTION (MAXRECURSION 0);

```

Historical-data assumption: This query treats months before the customer's first recorded order as zero-order months. That is valid only if the dataset's historical coverage is complete for those months.

## 4. Expected result

The following is the expected output based on your previously supplied SSMS results and the revised calendar logic. It is a prediction, not a new execution of the revised query.

| CustomerID | CustomerName | ActivityMonth | MonthlyOrderCount | Rolling3MonthOrderCount | PreviousRolling3MonthOrderCount | RollingTotalChange | TrendClassification |
| ---------- | ------------ | ------------- | ----------------- | ----------------------- | ------------------------------- | ------------------ | ------------------- |
| 1          | Amit         | 2026-01-01    | 2                 | 2                       | 0                               | 2                  | Increased           |
| 1          | Amit         | 2026-02-01    | 1                 | 3                       | 2                               | 1                  | Increased           |
| 1          | Amit         | 2026-03-01    | 2                 | 5                       | 3                               | 2                  | Increased           |
| 1          | Amit         | 2026-05-01    | 1                 | 3                       | 3                               | 0                  | Unchanged           |
| 2          | Priya        | 2026-01-01    | 1                 | 1                       | 0                               | 1                  | Increased           |
| 2          | Priya        | 2026-02-01    | 1                 | 2                       | 1                               | 1                  | Increased           |
| 2          | Priya        | 2026-03-01    | 1                 | 3                       | 2                               | 1                  | Increased           |
| 2          | Priya        | 2026-04-01    | 2                 | 4                       | 3                               | 1                  | Increased           |
| 2          | Priya        | 2026-05-01    | 1                 | 4                       | 4                               | 0                  | Unchanged           |
| 3          | Rahul        | 2026-01-01    | 1                 | 1                       | 0                               | 1                  | Increased           |
| 3          | Rahul        | 2026-02-01    | 1                 | 2                       | 1                               | 1                  | Increased           |
| 3          | Rahul        | 2026-04-01    | 1                 | 2                       | 2                               | 0                  | Unchanged           |
| 3          | Rahul        | 2026-05-01    | 1                 | 2                       | 2                               | 0                  | Unchanged           |
| 4          | Neha         | 2026-02-01    | 3                 | 3                       | 0                               | 3                  | Increased           |
| 5          | Vikas        | 2026-02-01    | 1                 | 1                       | 0                               | 1                  | Increased           |
| 5          | Vikas        | 2026-03-01    | 1                 | 2                       | 1                               | 1                  | Increased           |
| 5          | Vikas        | 2026-05-01    | 1                 | 2                       | 2                               | 0                  | Unchanged           |
| 6          | Karan        | 2026-01-01    | 2                 | 2                       | 0                               | 2                  | Increased           |
| 6          | Karan        | 2026-02-01    | 1                 | 3                       | 2                               | 1                  | Increased           |
| 6          | Karan        | 2026-03-01    | 1                 | 4                       | 3                               | 1                  | Increased           |
| 6          | Karan        | 2026-04-01    | 1                 | 3                       | 4                               | -1                 | Decreased           |
| 7          | Meera        | 2026-01-01    | 1                 | 1                       | 0                               | 1                  | Increased           |
| 7          | Meera        | 2026-03-01    | 1                 | 2                       | 1                               | 1                  | Increased           |
| 7          | Meera        | 2026-04-01    | 1                 | 2                       | 2                               | 0                  | Unchanged           |
| 8          | Arjun        | 2026-02-01    | 1                 | 1                       | 0                               | 1                  | Increased           |
| 8          | Arjun        | 2026-03-01    | 1                 | 2                       | 1                               | 1                  | Increased           |
| 8          | Arjun        | 2026-04-01    | 1                 | 3                       | 2                               | 1                  | Increased           |
| 8          | Arjun        | 2026-05-01    | 1                 | 3                       | 3                               | 0                  | Unchanged           |
| 9          | Pooja        | 2026-03-01    | 1                 | 1                       | 0                               | 1                  | Increased           |
| 10         | Rohit        | 2026-01-01    | 1                 | 1                       | 0                               | 1                  | Increased           |
| 10         | Rohit        | 2026-02-01    | 1                 | 2                       | 1                               | 1                  | Increased           |
| 10         | Rohit        | 2026-04-01    | 1                 | 2                       | 2                               | 0                  | Unchanged           |
| 10         | Rohit        | 2026-05-01    | 1                 | 2                       | 2                               | 0                  | Unchanged           |
| 11         | Sneha        | 2026-03-01    | 2                 | 2                       | 0                               | 2                  | Increased           |
| 11         | Sneha        | 2026-04-01    | 1                 | 3                       | 2                               | 1                  | Increased           |
| 12         | Dev          | 2026-01-01    | 1                 | 1                       | 0                               | 1                  | Increased           |
| 12         | Dev          | 2026-05-01    | 1                 | 1                       | 0                               | 1                  | Increased           |
| 13         | Isha         | 2026-02-01    | 1                 | 1                       | 0                               | 1                  | Increased           |
| 13         | Isha         | 2026-03-01    | 1                 | 2                       | 1                               | 1                  | Increased           |
| 13         | Isha         | 2026-05-01    | 1                 | 2                       | 2                               | 0                  | Unchanged           |
| 14         | Varun        | 2026-01-01    | 1                 | 1                       | 0                               | 1                  | Increased           |
| 14         | Varun        | 2026-02-01    | 1                 | 2                       | 1                               | 1                  | Increased           |
| 14         | Varun        | 2026-03-01    | 1                 | 3                       | 2                               | 1                  | Increased           |
| 14         | Varun        | 2026-04-01    | 1                 | 3                       | 3                               | 0                  | Unchanged           |
| 14         | Varun        | 2026-05-01    | 1                 | 3                       | 3                               | 0                  | Unchanged           |

## 5. Key concepts learned

| Concept                | What you practised                                          |
| ---------------------- | ----------------------------------------------------------- |
| `DATETRUNC()`          | Normalize dates to calendar months                          |
| Recursive CTE          | Generate a continuous monthly calendar                      |
| `COALESCE()`           | Replace missing monthly counts with zero                    |
| Windowed `SUM()`       | Calculate rolling three-month totals                        |
| `LAG()`                | Compare against the previous calendar month's rolling total |
| `CASE`                 | Classify increasing, decreasing, and unchanged trends       |
| Query processing order | Filter inactive months after window calculations            |

## 6. Errors and corrections to remember

- Using only `MIN(ActivityMonth)` as the calendar start: leaves the first active month with an incomplete rolling window. Moving back two months creates the required earlier calendar rows.
- Filtering inactive months before calculating the rolling sum: causes the window to operate over active rows instead of calendar months.
- Applying `LAG()` to active-month rows only: compares with the previous active month, which may be several calendar months earlier.
- Confusing a missing row with a known zero: zero-filling is correct only when the relevant data coverage is known to be complete.

## 7. Validation checklist

- Run the revised query in SSMS.
- Confirm the first active month has a previous rolling total of zero under the stated historical-data assumption.
- Confirm inactive months contribute to rolling totals but do not appear in the final result.
- Verify Dev's May row has a previous rolling total of zero.
- Compare the actual output with the expected result above.
- Save the final query in the specified folder.

## 8. Git commands

After validating the revised query and saving the file, use PowerShell:

```
git add "05_Advanced_SQL/task-035-customer-rolling-3-month-order-analysis.sql"
git commit -m "Add task 035 customer rolling three month analysis"
git push origin main
```

Git completion has not been confirmed.

Final assessment: Your approach demonstrates a strong grasp of monthly aggregation, recursive calendar generation, and window functions. The main improvement is to explicitly separate calendar completeness, historical-data availability, and final-report filtering—three distinct concerns in production analytics.

*/