/*

## Task 043 — Top 3 Orders per Customer

Filename: `task-043-top-3-orders-per-customer.sql`

Save folder: `06_Data_Engineering`

Database: `DataEngineeringPracticeDB_Lite`

### Business requirement

The sales analytics team wants to identify each customer's three highest-value orders to understand their largest transactions.

Write a SQL query against `dbo.Orders` that returns the top 3 orders by `TotalAmount` for every customer.

Your output must contain exactly these five columns, in this order:

1. `CustomerID`
2. `OrderID`
3. `OrderDate`
4. `TotalAmount`
5. `OrderRank`

### Business rules

- Rank orders separately for each customer.
- The highest `TotalAmount` must receive rank 1.
- If multiple orders have the same `TotalAmount`, use the most recent `OrderDate` as the tie-breaker.
- Return no more than three orders per customer.
- Customers with fewer than three orders should still appear with all their available orders.
- Sort the final result by `CustomerID` ascending, then `OrderRank` ascending.

### Constraints

- Use a window function.
- Do not use CTEs, temporary tables, or create database objects.
- Read-only query only.
- Start with `DataEngineeringPracticeDB_Lite`.

Save the file using the suggested filename, then submit your query and SSMS output. I'll review your attempt before providing hints or a solution.

*/

SELECT 
*
FROM
(SELECT 
	O.CustomerID,
	O.OrderID,
	O.OrderDate,
	O.TotalAmount,
	ROW_NUMBER() OVER (PARTITION BY O.CustomerID ORDER BY O.TotalAmount DESC, O.OrderDate DESC) AS RNK
FROM orders O) a
WHERE RNK IN (1,2,3)
ORDER BY CustomerID ASC, RNK ASC

/*

✅ Task 043 — Validated successfully.

Your SSMS output matches the business requirement. You returned exactly three orders per customer for all 10 customers in the Lite database: 30 rows total.

### Result validation

| Check                                      | Result |
| ------------------------------------------ | ------ |
| Highest order amount ranked first          | Pass   |
| Most recent date used as tie-breaker       | Pass   |
| Maximum three orders per customer          | Pass   |
| Customer IDs sorted ascending              | Pass   |
| Rank sorted ascending within each customer | Pass   |
| Output columns                             | Pass   |

Your query is correct. One optional improvement is adding `O.OrderID DESC` as a final tie-breaker inside `ROW_NUMBER()` to make rankings deterministic when both amount and date are identical.

## Final query for your repository

Filename: `task-043-top-3-orders-per-customer.sql`

Folder: `06_Data_Engineering`

```

USE DataEngineeringPracticeDB_Lite;
GO

SELECT
    CustomerID,
    OrderID,
    OrderDate,
    TotalAmount,
    RNK AS OrderRank
FROM
(
    SELECT
        O.CustomerID,
        O.OrderID,
        O.OrderDate,
        O.TotalAmount,
        ROW_NUMBER() OVER
        (
            PARTITION BY O.CustomerID
            ORDER BY
                O.TotalAmount DESC,
                O.OrderDate DESC,
                O.OrderID DESC
        ) AS RNK
    FROM dbo.Orders AS O
) AS RankedOrders
WHERE RNK <= 3
ORDER BY
    CustomerID ASC,
    RNK ASC;

```

I made two minor refinements: the output column is now named `OrderRank`, as requested, and the ranking includes `OrderID DESC` as a final tie-breaker.

### Key learning

- `ROW_NUMBER()` assigns a unique sequential number within each customer.
- `PARTITION BY` restarts the numbering for every customer.
- `RANK()` can produce ties and gaps; `ROW_NUMBER()` guarantees no more than three rows per customer when filtered to the first three numbers.
- A deterministic tie-breaker helps ensure repeatable results.

### Git commands

Save the final query, then run these commands from your repository root:

```

git status
git add "06_Data_Engineering/task-043-top-3-orders-per-customer.sql"
git commit -m "Add Task 043 top orders per customer"
git push origin main

```

Task 043 is complete. Ready for Task 044.

*/