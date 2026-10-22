/*

## Task 052 — Customer Revenue Contribution Analysis

Difficulty

Advanced

Database: `DataEngineeringPracticeDB_Lite`

Table: `dbo.Orders`

Filename: `task-052-customer-revenue-contribution.sql`

Folder: `06_Data_Engineering`

### Business requirement

The finance team wants to understand how much revenue each customer generates and what percentage of the company's total order revenue comes from that customer.

Write a SQL query that returns exactly these columns:

| Column                   | Description                                           |
| ------------------------ | ----------------------------------------------------- |
| `CustomerID`             | Customer identifier                                   |
| `CustomerRevenue`        | Total order revenue for the customer                  |
| `TotalRevenue`           | Overall order revenue across all customers            |
| `RevenueContributionPct` | Customer's percentage contribution to overall revenue |
| `RevenueRank`            | Customer's revenue ranking, highest first             |

### Business rules

1. Use `TotalAmount` from `dbo.Orders` as the revenue measure.
2. Calculate the percentage as customer revenue divided by overall revenue, multiplied by 100.
3. Round the percentage to two decimal places.
4. Rank customers by revenue in descending order. Break ties using `CustomerID` ascending.
5. Include all customers who have orders.
6. Sort the output by `RevenueRank` ascending.
7. Use read-only SQL. CTEs and window functions are permitted.

### Difficulty levels for future tasks

I'll label each new task using one of these levels:

| Level        | Focus                                                                |
| ------------ | -------------------------------------------------------------------- |
| Easy         | Basic querying and filtering                                         |
| Intermediate | Multiple concepts combined                                           |
| Medium       | Multi-step business logic                                            |
| High         | Complex analytical logic and edge cases                              |
| Advanced     | Multi-stage analytical problems and stronger validation requirements |

I'll also vary the difficulty across your learning journey rather than making every task advanced.

Your turn: Write the query independently and run it in SSMS. I’ll review your attempt first, explain mistakes after seeing your SQL, and validate the output you share. No hints before your attempt.

*/


WITH RevenueByCustomer AS
(
SELECT
	O.CustomerID,
	SUM(O.TotalAmount) AS CustomerRevenue
FROM Orders O
GROUP BY
	O.CustomerID
),
RANKING AS
(
SELECT 
	R.CustomerID,
	R.CustomerRevenue,
	SUM(R.CustomerRevenue) OVER() AS TotalRevenue,
	CAST(
    R.CustomerRevenue * 100.0
    / SUM(R.CustomerRevenue) OVER()
    AS DECIMAL(10,2)) AS RevenueContributionPct,
	ROW_NUMBER() OVER(ORDER BY R.CustomerRevenue DESC, R.CustomerID) AS RevenueRank
FROM RevenueByCustomer R
)

SELECT
	RNK.CustomerID,
	RNK.CustomerRevenue,
	RNK.TotalRevenue,
	RNK.RevenueContributionPct,
	RNK.RevenueRank
FROM RANKING RNK
ORDER BY RevenueRank

/*

## Task 052 — Output Validation

Your output confirms that the query is calculating customer revenue, overall revenue, and sequential revenue ranks as intended. There are 10 customers, with total revenue of 261,682.00.

One correction remains: the `RevenueContributionPct` values in your output have four to six decimal places, while the requirement specifies two decimal places. Your current expression calculates the percentage but does not explicitly cast the final result to `DECIMAL(10,2)`.

The ranking itself looks correct: Customer 1 ranks first with revenue of `31,332.40`, followed by Customer 10 and Customer 9.

### Final validated query

```

USE DataEngineeringPracticeDB_Lite;
GO

WITH RevenueByCustomer AS
(
    SELECT
        O.CustomerID,
        SUM(O.TotalAmount) AS CustomerRevenue
    FROM dbo.Orders AS O
    GROUP BY O.CustomerID
),
Ranking AS
(
    SELECT
        R.CustomerID,
        R.CustomerRevenue,
        SUM(R.CustomerRevenue) OVER () AS TotalRevenue,
        CAST(
            R.CustomerRevenue * 100.0
            / SUM(R.CustomerRevenue) OVER ()
            AS DECIMAL(10,2)
        ) AS RevenueContributionPct,
        ROW_NUMBER() OVER
        (
            ORDER BY R.CustomerRevenue DESC, R.CustomerID ASC
        ) AS RevenueRank
    FROM RevenueByCustomer AS R
)
SELECT
    CustomerID,
    CustomerRevenue,
    TotalRevenue,
    RevenueContributionPct,
    RevenueRank
FROM Ranking
ORDER BY RevenueRank ASC;

```

### Task record

- Task: 052 — Customer Revenue Contribution Analysis
- Difficulty: Advanced
- Filename: `task-052-customer-revenue-contribution.sql`
- Folder: `06_Data_Engineering`
- Database: `DataEngineeringPracticeDB_Lite`
- Status:&#x20;

  Complete



What you missed: Explicitly casting the final percentage to two decimal places.

What you learned: You can aggregate customer revenue first, use `SUM(...) OVER()` to calculate the overall total across those aggregated rows, then calculate each customer's contribution and ranking.

What to remember: SQL evaluates expressions according to their data types and precision rules. Casting the final calculated percentage ensures the output follows the required numeric format.

How to make it better: Use `DECIMAL` arithmetic for financial calculations, rank on the original revenue value rather than a rounded percentage, and validate that the contribution percentages total approximately 100%. Individually rounded percentages may total slightly above or below 100%.

### Git commands

Save the final query to `06_Data_Engineering/task-052-customer-revenue-contribution.sql`, then run:

```
git add 06_Data_Engineering/task-052-customer-revenue-contribution.sql
git commit -m "Complete task 052: customer revenue contribution"
git push origin main
```

These commands have not been executed or verified from this chat.

*/