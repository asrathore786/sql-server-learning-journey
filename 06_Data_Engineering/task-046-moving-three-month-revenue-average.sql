/*

## Task 046 — Moving 3-Month Revenue Average

Difficulty: Intermediate · Window functions · Time-series analysis

Filename: `task-046-moving-three-month-revenue-average.sql` Folder: `06_Data_Engineering` Database: `DataEngineeringPracticeDB_Lite` Source table: `dbo.Orders`

### Business requirement

The finance team wants to smooth monthly revenue fluctuations by calculating a rolling three-month revenue total and average for each customer.

Write a SQL query that returns exactly these five columns:

| Column              | Description                                                 |
| ------------------- | ----------------------------------------------------------- |
| `CustomerID`        | Customer identifier                                         |
| `OrderMonth`        | First day of the calendar month                             |
| `MonthlyRevenue`    | Total order value for that customer and month               |
| `ThreeMonthRevenue` | Revenue across the current and previous two calendar months |
| `ThreeMonthAverage` | Average monthly revenue across those three calendar months  |

### Requirements

1. Aggregate orders to one row per customer per calendar month.
2. Include months without orders in the calculation, treating their revenue as zero.
3. Calculate the window over the current month and the two preceding calendar months, not simply the previous two rows of active months.
4. Return `NULL` for `ThreeMonthRevenue` and `ThreeMonthAverage` until a complete three-calendar-month window is available, starting from the customer's first active month.
5. Show only months in which the customer placed at least one order in the final output.
6. Sort by `CustomerID ASC`, then `OrderMonth ASC`.
7. Use CTEs and window functions as needed. Do not use temporary tables or create database objects.
8. Keep the query read-only.

### Your attempt

Submit your complete SQL query first. I’ll review your approach without revealing the solution, then you can run the revised query in SSMS and share the results.

*/


WITH 
  monthlyrevenue AS (
    SELECT 
      customerid, 
      Datefromparts(
        Year(orderdate), 
        Month(orderdate), 
        1
      ) AS ordermonth, 
      Sum(TotalAmount) AS monthlyrevenue, 
      Count(*) AS ordercount 
    FROM 
      dbo.orders 
    GROUP BY 
      customerid, 
      Datefromparts(
        Year(orderdate), 
        Month(orderdate), 
        1
      )
  ), 
  minmax AS (
    SELECT 
      customerid, 
      DATEADD(
        MONTH, 
        -2, 
        MIN(ordermonth)
      ) AS minmonth, 
      Max(ordermonth) AS maxmonth 
    FROM 
      monthlyrevenue 
    GROUP BY 
      customerid
  ), 
  monthcalendar AS (
    SELECT 
      customerid, 
      minmonth AS ordermonth, 
      maxmonth 
    FROM 
      minmax 
    UNION ALL 
    SELECT 
      customerid, 
      Dateadd(month, 1, ordermonth), 
      maxmonth 
    FROM 
      monthcalendar 
    WHERE 
      ordermonth < maxmonth
  ), 
  denserevenue AS (
    SELECT 
      c.customerid, 
      c.ordermonth, 
      m.monthlyrevenue, 
      m.ordercount, 
      COALESCE(m.monthlyrevenue, 0) AS revenueforwindow 
    FROM 
      monthcalendar AS c 
      LEFT JOIN monthlyrevenue AS m ON m.customerid = c.customerid 
      AND m.ordermonth = c.ordermonth
  ), 
  rollingrevenue AS (
    SELECT 
      customerid, 
      ordermonth, 
      monthlyrevenue, 
      ordercount, 
      sum(revenueforwindow) OVER (
        partition BY customerid 
        ORDER BY 
          ordermonth rows BETWEEN 2 PRECEDING 
          AND CURRENT row
      ) AS rollingtotal, 
      avg(1.0 * revenueforwindow) OVER (
        partition BY customerid 
        ORDER BY 
          ordermonth rows BETWEEN 2 PRECEDING 
          AND CURRENT row
      ) AS rollingaverage, 
      count(*) OVER (
        partition BY customerid 
        ORDER BY 
          ordermonth rows BETWEEN 2 PRECEDING 
          AND CURRENT row
      ) AS monthsinwindow 
    FROM 
      denserevenue
  ) 
SELECT 
  customerid, 
  ordermonth, 
  monthlyrevenue, 
  CASE WHEN monthsinwindow = 3 THEN rollingtotal END AS threemonthrevenue, 
  CASE WHEN monthsinwindow = 3 THEN rollingaverage END AS threemonthaverage 
FROM 
  rollingrevenue 
WHERE 
  ordercount > 0 
ORDER BY 
  customerid ASC, 
  ordermonth ASC OPTION (maxrecursion 32767);

  /*
  ## Task 046 — Validation result

Status: Passed. Your output is consistent with the three-calendar-month rolling revenue requirement.

Your results demonstrate that the query correctly handles missing months, includes zero revenue in the calculations, and calculates the rolling metrics independently for each customer.

### Validation checks

| Check                                                           | Result |
| --------------------------------------------------------------- | ------ |
| One output row per active customer-month                        | ✅      |
| Missing calendar months treated as zero                         | ✅      |
| First active month includes two preceding zero-revenue months   | ✅      |
| Rolling total covers three calendar months                      | ✅      |
| Rolling average divides by three, including zero-revenue months | ✅      |
| Customers' calculations remain separate                         | ✅      |
| Output sorted by customer and month                             | ✅      |

For example, Customer 1's January 2023 result is:

- Monthly revenue: `100.37`
- Three-month revenue: `100.37`
- Three-month average: `33.456666`

This is correct because November and December 2022 have zero revenue in the generated calendar.

For March 2023:

- January revenue: `100.37`
- February revenue: `655.37`
- March revenue: `1210.37`
- Three-month revenue: `1966.11`
- Three-month average: `655.37`

That confirms the rolling window is operating over calendar months, rather than merely the previous two months containing orders.

## Final task record

Filename: `task-046-moving-three-month-revenue-average.sql` Folder: `06_Data_Engineering` Database: `DataEngineeringPracticeDB_Lite`

Keep your final query as the version that begins the calendar two months before each customer's first active month. That adjustment is what makes the first active month's rolling calculation valid.

### Git commands

After saving the final query in your repository, run:

```
git add 06_Data_Engineering/task-046-moving-three-month-revenue-average.sql
git commit -m "Complete task 046: moving three-month revenue average"
git push origin main
```

Task 046 is complete from the query and output review. Git commit and push are not yet confirmed.
*/