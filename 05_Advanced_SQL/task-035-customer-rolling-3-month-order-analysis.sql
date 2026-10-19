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
