/*

Suggested filename: `task-041-self-join-customer-order-analysis.sql`

Save folder: `06_Data_Engineering`

Database: `DataEngineeringPracticeDB`

## Task 041 — Customer Order Comparison Using a Self Join

Pattern: Self Join

### Business requirement

The Analytics team wants to identify customers who placed orders on two different dates where the later order had a higher `TotalAmount` than the earlier order.

Write a SQL Server query against `dbo.Orders` to identify every qualifying pair of orders for the same customer.

A pair qualifies when:

- Both orders belong to the same `CustomerID`.
- The first order occurred before the second order.
- The later order's `TotalAmount` is strictly greater than the earlier order's `TotalAmount`.
- An order must not be paired with itself.
- Each pair must appear only once.

### Expected output

Return exactly these columns:

| Column               | Description                       |
| -------------------- | --------------------------------- |
| `CustomerID`         | Customer who placed both orders   |
| `EarlierOrderID`     | ID of the earlier order           |
| `EarlierOrderDate`   | Date of the earlier order         |
| `EarlierOrderAmount` | Amount of the earlier order       |
| `LaterOrderID`       | ID of the later order             |
| `LaterOrderDate`     | Date of the later order           |
| `LaterOrderAmount`   | Amount of the later order         |
| `AmountIncrease`     | Later amount minus earlier amount |

### Technical constraints

1. Use `dbo.Orders` as the source table.
2. Use a self join to compare orders belonging to the same customer.
3. Do not create or modify database objects.
4. Do not insert, update, or delete any data.
5. Sort by `CustomerID` ascending, `EarlierOrderDate` ascending, and `LaterOrderDate` ascending.
6. Return only pairs that satisfy all business rules.

### Acceptance criteria

Your query must correctly identify every qualifying pair, calculate the amount increase, avoid pairing an order with itself, and avoid duplicate representations of the same pair.

Save your solution in the suggested file.

Your turn: Write the query independently and run it in SSMS. Share your SQL and actual output. I will review your attempt before providing hints or a solution.

*/

WITH Order_Summary AS
(
SELECT
	First.CustomerID,
	First.OrderID AS EarlierOrderID,
	First.OrderDate AS EarlierOrderDate,
	First.TotalAmount AS EarlierOrderAmount,
	Second.OrderID AS LaterOrderID,
	Second.OrderDate AS LaterOrderDate,
	Second.TotalAmount AS LaterOrderAmount
FROM Orders First
	INNER JOIN Orders Second
		ON Second.CustomerID = First.CustomerID
        AND First.OrderDate < Second.OrderDate
		AND First.TotalAmount < Second.TotalAmount
)

SELECT 
	CustomerID,
	EarlierOrderID,
	EarlierOrderDate,
	EarlierOrderAmount,
	LaterOrderID,
	LaterOrderDate,
	LaterOrderAmount,
	LaterOrderAmount - EarlierOrderAmount AS AmountIncrease
FROM Order_Summary

ORDER BY CustomerID ASC,
		EarlierOrderDate ASC,
		LaterOrderDate ASC

/*

## Task 041 — Customer Order Comparison Using a Self Join

Logic reviewed

Execution not yet confirmed

Filename: `task-041-self-join-customer-order-analysis.sql`

Folder: `06_Data_Engineering`

### 1. Final query

```

USE DataEngineeringPracticeDB;
GO

WITH Order_Summary AS
(
    SELECT
        First.CustomerID,
        First.OrderID AS EarlierOrderID,
        First.OrderDate AS EarlierOrderDate,
        First.TotalAmount AS EarlierOrderAmount,
        Second.OrderID AS LaterOrderID,
        Second.OrderDate AS LaterOrderDate,
        Second.TotalAmount AS LaterOrderAmount
    FROM dbo.Orders AS First
    INNER JOIN dbo.Orders AS Second
        ON Second.CustomerID = First.CustomerID
        AND First.OrderDate < Second.OrderDate
        AND First.TotalAmount < Second.TotalAmount
)
SELECT
    CustomerID,
    EarlierOrderID,
    EarlierOrderDate,
    EarlierOrderAmount,
    LaterOrderID,
    LaterOrderDate,
    LaterOrderAmount,
    LaterOrderAmount - EarlierOrderAmount AS AmountIncrease
FROM Order_Summary
ORDER BY
    CustomerID ASC,
    EarlierOrderDate ASC,
    LaterOrderDate ASC;

```

I removed the redundant `OrderID` inequality condition and qualified `Orders` with `dbo`. Neither change alters the intended result.

### 2. What you learned

- Self join: Compare records within the same table using two aliases.
- Pair direction: `First.OrderDate < Second.OrderDate` ensures the earlier order is always on the left.
- Multiple conditions: The pair must belong to the same customer, have different dates, and show an increase in order value.
- Calculated column: Subtract the earlier amount from the later amount without converting the decimal to an integer.
- CTE: Keep the comparison logic separate from the final projection and sorting.

### 3. Validation checklist

After running the query in SSMS, verify:

- All rows contain the same `CustomerID` on both sides of each pair.
- `EarlierOrderDate` is strictly before `LaterOrderDate`.
- `LaterOrderAmount` is greater than `EarlierOrderAmount`.
- `AmountIncrease` equals the difference between the two amounts.
- Results are sorted by customer, earlier date, and later date.

The query has passed visual and logical review. Actual execution and output validation are still pending.

### 4. Git commands

Save the query in:

`06_Data_Engineering\task-041-self-join-customer-order-analysis.sql`

Then run these commands in PowerShell from your repository root:

```

git status
git add "06_Data_Engineering/task-041-self-join-customer-order-analysis.sql"
git commit -m "Add Task 041 self join customer order analysis"
git push origin main

```

Run `git status` first to confirm you are in the correct repository. The commands stage only this SQL file, commit it, and push the commit to `main`.

Next: Execute the query before treating Task 041 as fully validated.

*/