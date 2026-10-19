/*

## Task 036 — Customer Purchase Reactivation Analysis

## Advanced SQL Practice

SQL Server 2022 · PracticeDatabase

Save your file first

Filename: `task-036-customer-purchase-reactivation-analysis.sql`

Folder: `05_Advanced_SQL`

### Business requirement

The business wants to identify customers who stopped purchasing for at least two complete calendar months and subsequently returned.

For every reactivation event, return one row showing the customer's last active month before the gap, the month they returned, the number of inactive calendar months, and the order counts before and after the gap.

### Expected output

| Column                       | Description                                                                     |
| ---------------------------- | ------------------------------------------------------------------------------- |
| `CustomerID`                 | Customer identifier                                                             |
| `CustomerName`               | Customer name                                                                   |
| `PreviousActiveMonth`        | Last month in which the customer placed an order before the gap                 |
| `ReturnMonth`                | Month the customer placed an order after the gap                                |
| `InactiveMonths`             | Number of complete calendar months with no orders between the two active months |
| `PreviousMonthOrderCount`    | Number of orders in the previous active month                                   |
| `ReturnMonthOrderCount`      | Number of orders in the return month                                            |
| `OrderCountChange`           | Return-month count minus previous-active-month count                            |
| `ReactivationClassification` | Classification based on the length of inactivity                                |

### Business rules

1. Aggregate orders to one row per customer per active calendar month.
2. A reactivation requires at least two complete inactive calendar months between two active months.
3. For example, January followed by April qualifies because February and March were inactive. January followed by March does not qualify because only February was inactive.
4. Count all orders regardless of `Status`.
5. Identify every qualifying reactivation event, not just the customer's first return.
6. Exclude customers who never ordered and customers whose activity never meets the reactivation condition.
7. Use these classifications:
   - `Short-Term Reactivation` for 2–3 inactive months.
   - `Long-Term Reactivation` for 4 or more inactive months.
8. Sort by `CustomerID ASC`, then `ReturnMonth ASC`.

### Your task

Write the SQL query independently. You can use the window functions and CTE patterns you have practised, but choose the approach yourself.

Remember your learning objective: reason through the calendar gap correctly, distinguish the number of inactive months from the difference between month dates, and validate that each qualifying return is captured.

Submit your query first. I will review your logic and identify errors without revealing the full solution before your attempt.

*/

WITH CTE_ActivityMonth AS
(
    SELECT
        C.CustomerID,
        C.CustomerName,
        DATETRUNC(MONTH, O.OrderDate) AS ActiveMonth,
        COUNT(*) AS OrderCount
    FROM Customers C
    INNER JOIN Orders O
        ON O.CustomerID = C.CustomerID
    GROUP BY
        C.CustomerID,
        C.CustomerName,
        DATETRUNC(MONTH, O.OrderDate)
),

MonthlyWithPrevious AS
(
    SELECT
        CustomerID,
        CustomerName,
        ActiveMonth,
        OrderCount,
        LAG(ActiveMonth) OVER(PARTITION BY CustomerID ORDER BY ActiveMonth) AS PreviousActiveMonth,
        LAG(OrderCount) OVER(PARTITION BY CustomerID ORDER BY ActiveMonth) AS PreviousMonthOrderCount
    FROM CTE_ActivityMonth
),
ReactivationGaps AS
(
SELECT
    CustomerID,
    CustomerName,
    PreviousActiveMonth,
    ActiveMonth AS ReturnMonth,
    DATEDIFF(MONTH,PreviousActiveMonth,ActiveMonth) - 1 AS InactiveMonths,
    PreviousMonthOrderCount,
    OrderCount AS ReturnMonthOrderCount,
     OrderCount - PreviousMonthOrderCount AS OrderCountChange
FROM MonthlyWithPrevious
)
SELECT 
    CustomerID,
    CustomerName,
    PreviousActiveMonth,
    ReturnMonth,
    InactiveMonths,
    PreviousMonthOrderCount,
    ReturnMonthOrderCount,
    OrderCountChange,
    CASE
        WHEN InactiveMonths BETWEEN 2 AND 3 THEN 'Short-Term Reactivation'
        WHEN InactiveMonths >= 4 THEN 'Long-Term Reactivation'
    END AS ReactivationClassification
FROM ReactivationGaps
WHERE InactiveMonths >= 2 AND PreviousActiveMonth IS NOT NULL
ORDER BY CustomerID ASC, ReturnMonth ASC;


/*

# Task 036 — Final Learning Record

Task: Customer Purchase Reactivation Analysis Difficulty: Advanced intermediate Status: SQL logic reviewed; local execution and Git push not yet confirmed.

## 1. File details

- Filename: `task-036-customer-purchase-reactivation-analysis.sql`
- Folder: `05_Advanced_SQL`
- Full local folder: `C:\Users\asrat\OneDrive\Desktop\SQL_STUDY\SQL-Server-Learning-Journey\sql-server-learning-journey\05_Advanced_SQL`

## 2. Business requirement

Identify every customer reactivation event where a customer had no orders for at least two complete calendar months and subsequently placed orders again.

The query must return the previous active month, return month, inactive-month count, order counts before and after the gap, order count change, and a classification of the reactivation as short-term or long-term.

Rules:

- Aggregate orders by customer and active calendar month.
- Count all orders regardless of status.
- Require at least two inactive months between active months.
- Classify 2–3 inactive months as `Short-Term Reactivation`.
- Classify 4 or more inactive months as `Long-Term Reactivation`.
- Include every qualifying event and sort by customer ID and return month.

## 3. Final validated query

Save the following as `task-036-customer-purchase-reactivation-analysis.sql`.

```

/*
Task 036: Customer Purchase Reactivation Analysis

Purpose:
Identify customers who return to purchasing after at least
two complete inactive calendar months.

Concepts:
CTEs, monthly aggregation, LAG(), DATEDIFF(), CASE.
*/

WITH CTE_ActivityMonth AS
(
    -- Step 1: Aggregate all orders by customer and active month.
    SELECT
        C.CustomerID,
        C.CustomerName,
        DATETRUNC(MONTH, O.OrderDate) AS ActiveMonth,
        COUNT(*) AS OrderCount
    FROM Customers C
    INNER JOIN Orders O
        ON O.CustomerID = C.CustomerID
    GROUP BY
        C.CustomerID,
        C.CustomerName,
        DATETRUNC(MONTH, O.OrderDate)
),
MonthlyWithPrevious AS
(
    -- Step 2: Retrieve the previous active month and its order count.
    SELECT
        CustomerID,
        CustomerName,
        ActiveMonth,
        OrderCount,
        LAG(ActiveMonth) OVER
        (
            PARTITION BY CustomerID
            ORDER BY ActiveMonth
        ) AS PreviousActiveMonth,
        LAG(OrderCount) OVER
        (
            PARTITION BY CustomerID
            ORDER BY ActiveMonth
        ) AS PreviousMonthOrderCount
    FROM CTE_ActivityMonth
),
ReactivationGaps AS
(
    -- Step 3: Calculate the inactive months between active months.
    SELECT
        CustomerID,
        CustomerName,
        PreviousActiveMonth,
        ActiveMonth AS ReturnMonth,
        DATEDIFF(
            MONTH,
            PreviousActiveMonth,
            ActiveMonth
        ) - 1 AS InactiveMonths,
        PreviousMonthOrderCount,
        OrderCount AS ReturnMonthOrderCount,
        OrderCount - PreviousMonthOrderCount AS OrderCountChange
    FROM MonthlyWithPrevious
)
-- Step 4: Return and classify qualifying reactivation events.
SELECT
    CustomerID,
    CustomerName,
    PreviousActiveMonth,
    ReturnMonth,
    InactiveMonths,
    PreviousMonthOrderCount,
    ReturnMonthOrderCount,
    OrderCountChange,
    CASE
        WHEN InactiveMonths BETWEEN 2 AND 3
            THEN 'Short-Term Reactivation'
        WHEN InactiveMonths >= 4
            THEN 'Long-Term Reactivation'
    END AS ReactivationClassification
FROM ReactivationGaps
WHERE InactiveMonths >= 2
  AND PreviousActiveMonth IS NOT NULL
ORDER BY
    CustomerID ASC,
    ReturnMonth ASC;

```

## 4. Expected output structure

The actual rows depend on the data in your local `PracticeDatabase`. I have not executed this query against your database, so the following is an illustrative example of the output format, not your actual results.

| CustomerID | CustomerName | PreviousActiveMonth | ReturnMonth | InactiveMonths | PreviousMonthOrderCount | ReturnMonthOrderCount | OrderCountChange | ReactivationClassification |
| ---------- | ------------ | ------------------- | ----------- | -------------- | ----------------------- | --------------------- | ---------------- | -------------------------- |
| 1          | Amit         | 2026-01-01          | 2026-04-01  | 2              | 2                       | 1                     | -1               | Short-Term Reactivation    |
| 2          | Priya        | 2026-01-01          | 2026-04-01  | 2              | 1                       | 2                     | 1                | Short-Term Reactivation    |
| 3          | Rahul        | 2026-01-01          | 2026-05-01  | 3              | 1                       | 1                     | 0                | Long-Term Reactivation     |

The example names and counts above are illustrative only. In particular, a three-month gap in `DATEDIFF` means two inactive months, so it qualifies as short-term reactivation.

## 5. What you learned

| Concept                       | Key lesson                                                               |
| ----------------------------- | ------------------------------------------------------------------------ |
| `DATETRUNC(MONTH, OrderDate)` | Normalizes dates to calendar-month boundaries.                           |
| `GROUP BY`                    | Establishes one row per customer per active month.                       |
| `LAG()`                       | Retrieves the previous active-month record for the same customer.        |
| `DATEDIFF(MONTH, ...) - 1`    | Calculates the number of inactive calendar months between active months. |
| `CASE`                        | Converts the inactive-month count into a business classification.        |
| Filtering                     | Retains only reactivation events with at least two inactive months.      |

### Errors and improvements recorded

1. Incorrect month-gap interpretation: You initially used `DATEDIFF` without subtracting one. You corrected it.
2. Unnecessary complexity: You introduced recursive calendar generation and `MIN()`/`MAX()` window expressions. You returned to the simpler `LAG()` approach.
3. Reversed subtraction: You initially calculated previous orders minus return-month orders. You corrected it to `OrderCount - PreviousMonthOrderCount`.
4. Column meaning: An intermediate attempt assigned a date to a column intended to contain an order count. Check the meaning and data type of every output column before finalizing a query.

### Validation checklist

Before marking the task complete, run it in SSMS and check:

- January → March is excluded because only one month is inactive.
- January → April is included with two inactive months.
- Two or three inactive months are classified as short-term.
- Four or more inactive months are classified as long-term.
- `OrderCountChange` is return-month count minus previous-month count.
- Each qualifying event appears once, and the results are sorted correctly.

## 6. Git commands

After saving the SQL file and validating the output in SSMS, open PowerShell in your repository directory:

```
cd "C:\Users\asrat\OneDrive\Desktop\SQL_STUDY\SQL-Server-Learning-Journey\sql-server-learning-journey"

git status

git add "05_Advanced_SQL/task-036-customer-purchase-reactivation-analysis.sql"

git commit -m "Add task 036 customer purchase reactivation analysis"

git push origin main
```

If Git reports that there is nothing to commit, check `git status` before proceeding.

## 7. Final assessment

Task 036: Logic reviewed, execution pending confirmation.

Your most important improvement area was translating the number of calendar-month boundaries into the number of genuinely inactive months. You also improved your ability to choose the appropriate window function and avoid unnecessary CTE complexity.

Once you run the query and confirm the output, share the result if you want a data-level validation before marking Task 036 complete.

*/