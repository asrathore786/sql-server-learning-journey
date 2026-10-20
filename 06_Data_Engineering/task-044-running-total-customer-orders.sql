/*
## Task 044 — Running Total of Customer Orders

Filename: `task-044-running-total-customer-orders.sql` Folder: `06_Data_Engineering` Database: `DataEngineeringPracticeDB_Lite` Difficulty: Intermediate

### Business requirement

The business wants to understand how each customer's cumulative order value grows over time. Write a SQL query that calculates a running total of order value for each customer, ordered chronologically.

Use `dbo.Orders` in `DataEngineeringPracticeDB_Lite`.

Your result must include exactly these five columns, in this order:

| Column         | Description                                                                    |
| -------------- | ------------------------------------------------------------------------------ |
| `CustomerID`   | Customer identifier                                                            |
| `OrderID`      | Order identifier                                                               |
| `OrderDate`    | Date the order was placed                                                      |
| `TotalAmount`  | Value of the individual order                                                  |
| `RunningTotal` | Cumulative value of that customer's orders up to and including the current row |

### Requirements

1. Calculate the running total independently for each customer.
2. Process each customer's orders by `OrderDate` ascending.
3. If multiple orders have the same date, use `OrderID` ascending to determine their sequence.
4. Include every order, even when a customer has many orders.
5. Restart the running total for each new customer.
6. Sort the final result by `CustomerID` ascending, then `OrderDate` ascending, then `OrderID` ascending.
7. Use a window function. Do not use a CTE, temporary table, or create any database objects.
8. This must be a read-only query.

### Your task

Write the complete SQL query and submit your first attempt. Don't worry about making it perfect; I'll review your query before revealing a solution.
*/

SELECT
	O.CustomerID,
	O.OrderID,
	O.OrderDate,
	O.TotalAmount,
	SUM(O.TotalAmount) OVER (PARTITION BY O.CustomerID ORDER BY O.OrderDate ASC, O.OrderID ASC) AS RunningTotal
FROM orders O
ORDER BY 
	O.CustomerID ASC,
	O.OrderDate ASC,
	O.OrderID ASC

/*
## Task 044 — Validated ✅

Your SSMS output confirms that the running total is working correctly for the displayed records.

What you got right:

- `SUM() OVER (...)` calculates the cumulative order value.
- `PARTITION BY CustomerID` resets the total for each customer.
- `ORDER BY OrderDate, OrderID` establishes the correct sequence.
- `TotalAmount` is included in the output, as required.

### Example: Customer 1

| OrderDate  | OrderID | TotalAmount | RunningTotal |
| ---------- | ------- | ----------- | ------------ |
| 2023-01-01 | 1       | 100.37      | 100.37       |
| 2023-02-10 | 1501    | 655.37      | 755.74       |
| 2023-03-22 | 3001    | 1,210.37    | 1,966.11     |
| 2023-05-01 | 4501    | 1,765.37    | 3,731.48     |

Each running total equals the previous cumulative total plus the current order amount. Customer 2 correctly starts again at `100.74`, rather than continuing Customer 1's total.

### Task record

Filename: `task-044-running-total-customer-orders.sql` Folder: `06_Data_Engineering` Status: Complete — query reviewed and output confirmed.

Core concept learned: running totals with window aggregate functions.

One useful refinement for production SQL is to specify the window frame explicitly:

```
SUM(O.TotalAmount) OVER
(
    PARTITION BY O.CustomerID
    ORDER BY O.OrderDate ASC, O.OrderID ASC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS RunningTotal
```

This makes the row-by-row accumulation explicit rather than relying on SQL Server's default window frame.

### Git commands

After saving the final query under the filename above, run:

```
git add "06_Data_Engineering/task-044-running-total-customer-orders.sql"
git commit -m "Add Task 044 customer order running total"
git push origin main
```

## Next: Task 045 — Month-over-Month Revenue Comparison

You'll practice comparing monthly revenue with the previous month using a window function. The challenge will involve monthly aggregation, `LAG()`, and handling missing months correctly.
*/