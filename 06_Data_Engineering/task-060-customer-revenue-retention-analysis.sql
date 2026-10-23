/*

## Task 060 — Customer Revenue Retention Analysis

Filename: `task-060-customer-revenue-retention-analysis.sql`

Save folder: `06_Data_Engineering`

Difficulty: Advanced

Database: `DataEngineeringPracticeDB_Lite`

Tables: `dbo.Customers`, `dbo.Orders`

### Business requirement

The Finance team wants to identify customers whose revenue has declined between two consecutive calendar quarters. Prepare a customer-level quarterly revenue comparison for Q2 2026 and Q3 2026.

Include every customer, even if they had no orders in either quarter. Calculate each customer's revenue for both quarters, the absolute revenue change, and the percentage change.

Use these business rules:

- Q2 2026: 1 April through 30 June 2026.
- Q3 2026: 1 July through 30 September 2026.
- Revenue is the sum of `Orders.TotalAmount` for orders placed within the quarter.
- Treat a missing quarter's revenue as zero.
- Calculate revenue change as Q3 revenue minus Q2 revenue.
- Calculate percentage change relative to Q2 revenue. If Q2 revenue is zero, return `NULL` for percentage change to avoid division by zero.
- Classify each customer using the following rules:

| Condition                                     | RevenueTrend               |
| --------------------------------------------- | -------------------------- |
| Q2 revenue = 0 and Q3 revenue = 0             | `No Revenue Both Quarters` |
| Q2 revenue = 0 and Q3 revenue > 0             | `New Revenue in Q3`        |
| Q3 revenue = 0 and Q2 revenue > 0             | `Revenue Lost in Q3`       |
| Q3 revenue > Q2 revenue                       | `Revenue Increased`        |
| Q3 revenue < Q2 revenue                       | `Revenue Declined`         |
| Q3 revenue = Q2 revenue and both are positive | `Revenue Unchanged`        |

### Expected output

| Column             | Description                             |
| ------------------ | --------------------------------------- |
| `CustomerID`       | Customer identifier                     |
| `CustomerName`     | Customer name                           |
| `Q2Revenue`        | Total revenue in Q2 2026                |
| `Q3Revenue`        | Total revenue in Q3 2026                |
| `RevenueChange`    | Q3 revenue minus Q2 revenue             |
| `RevenueChangePct` | Percentage change from Q2 to Q3         |
| `RevenueTrend`     | Classification based on the rules above |

Sort the output by `RevenueChange` ascending, then `CustomerID` ascending.

### Your task

Write the complete SQL query and run it in SSMS. Submit your query first, and I'll review your logic before you execute it.

I won't provide hints or a solution before your attempt.

*/

WITH Q2Revenue AS (
    SELECT 
        c.CustomerID,
        c.CustomerName,
        ISNULL(SUM(o.TotalAmount), 0) AS Q2Revenue
    FROM 
        dbo.Customers c
    LEFT JOIN 
        dbo.Orders o ON c.CustomerID = o.CustomerID 
                      AND o.OrderDate >= '20260401' AND o.OrderDate < '20260701'
    GROUP BY 
        c.CustomerID, c.CustomerName
),
Q3Revenue AS (
    SELECT 
        c.CustomerID,
        ISNULL(SUM(o.TotalAmount), 0) AS Q3Revenue
    FROM 
        dbo.Customers c
    LEFT JOIN 
        dbo.Orders o ON c.CustomerID = o.CustomerID 
                      AND o.OrderDate >= '2026-07-01' AND o.OrderDate < '2026-10-01'
    GROUP BY 
        c.CustomerID, c.CustomerName
)

SELECT
	Q2.customerID,
	Q2.CustomerName,
	Q2.Q2Revenue,
	Q3.Q3Revenue,
    Q3.Q3Revenue - Q2.Q2Revenue AS RevenueChange,
    CASE 
        WHEN q2.Q2Revenue = 0 THEN NULL
        ELSE (q3.Q3Revenue - q2.Q2Revenue) * 100.0 / q2.Q2Revenue
    END AS RevenueChangePct,
    CASE
        WHEN Q2.Q2Revenue = 0 AND Q3.Q3Revenue = 0 THEN 'No Revenue Both Quarters'
        WHEN Q2.Q2Revenue = 0 AND Q3.Q3Revenue > 0 THEN 'New Revenue in Q3'
        WHEN Q2.Q2Revenue > 0 AND Q3.Q3Revenue = 0 THEN 'Revenue Lost in Q3'
        WHEN Q3.Q3Revenue > Q2.Q2Revenue THEN 'Revenue Increased'
        WHEN Q3.Q3Revenue < Q2.Q2Revenue THEN 'Revenue Declined'
        WHEN Q2.Q2Revenue = Q3.Q3Revenue THEN 'Revenue Unchanged'
    END AS RevenueTrend
FROM Q2Revenue Q2
LEFT JOIN Q3Revenue Q3
	ON Q2.CustomerID = Q3.CustomerID
ORDER BY 
    RevenueChange ASC,
    Q2.CustomerID ASC

/*

Here is the full Task 060 completion record, following your SQL learning workflow: business requirement, final validated query, test results, lessons learned, and Git commands.

## Task 060 — Customer Revenue Retention Analysis

Task status

Completed

## Customer Revenue Retention Analysis

Folder: `06_Data_Engineering`

File: `task-060-customer-revenue-retention-analysis.sql`

Database: `DataEngineeringPracticeDB_Lite`

### 1. Business requirement

Analyze every customer's revenue in Q2 2026 and Q3 2026.

- Q2: April 1 through June 30, 2026.
- Q3: July 1 through September 30, 2026.
- Include customers even if they had no orders in either quarter.
- Calculate Q2 revenue, Q3 revenue, absolute revenue change and percentage change.
- Return `NULL` for percentage change when Q2 revenue is zero.
- Classify each customer's revenue trend.
- Sort by revenue change ascending, followed by CustomerID ascending.

### 2. Final SQL query

```

WITH Q2Revenue AS (
    SELECT
        c.CustomerID,
        c.CustomerName,
        ISNULL(SUM(o.TotalAmount), 0) AS Q2Revenue
    FROM dbo.Customers AS c
    LEFT JOIN dbo.Orders AS o
        ON c.CustomerID = o.CustomerID
        AND o.OrderDate >= '20260401'
        AND o.OrderDate < '20260701'
    GROUP BY
        c.CustomerID,
        c.CustomerName
),
Q3Revenue AS (
    SELECT
        c.CustomerID,
        ISNULL(SUM(o.TotalAmount), 0) AS Q3Revenue
    FROM dbo.Customers AS c
    LEFT JOIN dbo.Orders AS o
        ON c.CustomerID = o.CustomerID
        AND o.OrderDate >= '20260701'
        AND o.OrderDate < '20261001'
    GROUP BY
        c.CustomerID,
        c.CustomerName
)
SELECT
    Q2.CustomerID,
    Q2.CustomerName,
    Q2.Q2Revenue,
    Q3.Q3Revenue,
    Q3.Q3Revenue - Q2.Q2Revenue AS RevenueChange,
    CASE
        WHEN Q2.Q2Revenue = 0 THEN NULL
        ELSE
            (Q3.Q3Revenue - Q2.Q2Revenue)
            * 100.0 / Q2.Q2Revenue
    END AS RevenueChangePct,
    CASE
        WHEN Q2.Q2Revenue = 0
             AND Q3.Q3Revenue = 0
            THEN 'No Revenue Both Quarters'
        WHEN Q2.Q2Revenue = 0
             AND Q3.Q3Revenue > 0
            THEN 'New Revenue in Q3'
        WHEN Q2.Q2Revenue > 0
             AND Q3.Q3Revenue = 0
            THEN 'Revenue Lost in Q3'
        WHEN Q3.Q3Revenue > Q2.Q2Revenue
            THEN 'Revenue Increased'
        WHEN Q3.Q3Revenue < Q2.Q2Revenue
            THEN 'Revenue Declined'
        WHEN Q2.Q2Revenue = Q3.Q3Revenue
            THEN 'Revenue Unchanged'
    END AS RevenueTrend
FROM Q2Revenue AS Q2
LEFT JOIN Q3Revenue AS Q3
    ON Q2.CustomerID = Q3.CustomerID
ORDER BY
    RevenueChange ASC,
    Q2.CustomerID ASC;

```

### 3. Full result from your SSMS execution

The following is the complete output you shared, with all 20 customers.

| CustomerID | CustomerName  | Q2Revenue | Q3Revenue | RevenueChange | RevenueChangePct | RevenueTrend             |
| ---------- | ------------- | --------- | --------- | ------------- | ---------------- | ------------------------ |
| 5          | Vihaan Rao    | 75000.00  | 0.00      | -75000.00     | -100.000000      | Revenue Lost in Q3       |
| 2          | Priya Mehta   | 12000.00  | 4000.00   | -8000.00      | -66.666666       | Revenue Declined         |
| 6          | Sara Khan     | 4500.00   | 0.00      | -4500.00      | -100.000000      | Revenue Lost in Q3       |
| 12         | Tara Iyer     | 3000.00   | 0.00      | -3000.00      | -100.000000      | Revenue Lost in Q3       |
| 3          | Kabir Verma   | 5000.00   | 5000.00   | 0.00          | 0.000000         | Revenue Unchanged        |
| 7          | Arjun Patel   | 0.00      | 0.00      | 0.00          | NULL             | No Revenue Both Quarters |
| 8          | Ishita Nair   | 0.00      | 0.00      | 0.00          | NULL             | No Revenue Both Quarters |
| 9          | Rohan Das     | 0.00      | 0.00      | 0.00          | NULL             | No Revenue Both Quarters |
| 10         | Meera Joshi   | 0.00      | 0.00      | 0.00          | NULL             | No Revenue Both Quarters |
| 13         | Neil Kapoor   | 0.00      | 0.00      | 0.00          | NULL             | No Revenue Both Quarters |
| 14         | Zoya Siddiqui | 0.00      | 0.00      | 0.00          | NULL             | No Revenue Both Quarters |
| 15         | Aditya Singh  | 0.00      | 0.00      | 0.00          | NULL             | No Revenue Both Quarters |
| 16         | Kiara Bansal  | 0.00      | 0.00      | 0.00          | NULL             | No Revenue Both Quarters |
| 20         | Noor Ali      | 0.00      | 0.00      | 0.00          | NULL             | No Revenue Both Quarters |
| 17         | Yash Chawla   | 0.00      | 2250.00   | 2250.00       | NULL             | New Revenue in Q3        |
| 18         | Riya Sen      | 0.00      | 2750.00   | 2750.00       | NULL             | New Revenue in Q3        |
| 19         | Om Prakash    | 0.00      | 3250.00   | 3250.00       | NULL             | New Revenue in Q3        |
| 4          | Anaya Gupta   | 0.00      | 15000.00  | 15000.00      | NULL             | New Revenue in Q3        |
| 1          | Aarav Sharma  | 10000.00  | 35001.00  | 25001.00      | 250.010000       | Revenue Increased        |
| 11         | Dev Malhotra  | 0.00      | 40001.00  | 40001.00      | NULL             | New Revenue in Q3        |

### 4. Test coverage

Customers returned

## 20

Revenue Increased

### 1

Revenue Declined

### 1

Revenue Unchanged

### 1

Revenue Lost in Q3

### 3

New Revenue in Q3

### 5

No Revenue Both Quarters

### 9

All six trend categories are now represented in the output. The three comparison categories—increased, declined and unchanged—are demonstrated by Aarav, Priya and Kabir, respectively.

### 5. Key SQL lessons

1. Conditional aggregation through joins: filtering order dates in the `ON` clause preserves customers with no matching orders.
2. Half-open date ranges: `>= '20260401' AND < '20260701'` safely includes all timestamps on June 30.
3. Signed revenue change: `Q3Revenue - Q2Revenue` preserves whether revenue rose or fell.
4. Percentage change: the formula uses Q2 as the baseline and returns `NULL` when the baseline is zero.
5. CASE ordering: zero-revenue and new/lost-revenue scenarios are evaluated before the general increase/decrease cases.
6. Deterministic sorting: adding CustomerID as a second sort key makes ties predictable.

### 6. Git commands

Save the query in the specified file, then execute these commands in PowerShell from your repository root:

```
git add "06_Data_Engineering/task-060-customer-revenue-retention-analysis.sql"
git commit -m "Complete task 060 customer revenue retention analysis"
git push origin main
```

These commands have not been executed by me.

Task 060 is complete based on the SQL and results you supplied.

*/