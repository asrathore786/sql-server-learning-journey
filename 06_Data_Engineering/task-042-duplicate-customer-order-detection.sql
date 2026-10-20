/*

Task 042 — Duplicate Detection Using `GROUP BY` and `HAVING`

Suggested filename: `task-042-duplicate-customer-order-detection.sql`

Save folder: `06_Data_Engineering`

Database: `DataEngineeringPracticeDB_Lite`

## Business requirement

The operations team suspects that some customers may have placed multiple orders with the same order date and exactly the same total amount. They want to identify these potential duplicate order groups for investigation.

Write a SQL query against `dbo.Orders` to return groups where the same `CustomerID`, `OrderDate`, and `TotalAmount` occur more than once.

Your output must contain exactly these five columns, in this order:

1. `CustomerID`
2. `OrderDate`
3. `TotalAmount`
4. `DuplicateOrderCount`
5. `DuplicateExcessCount`

Definitions:

- `DuplicateOrderCount`: total number of orders in the matching group.
- `DuplicateExcessCount`: number of orders beyond the first order in that group.
- Only return groups with more than one order.
- Sort by `DuplicateOrderCount` descending, then `CustomerID` ascending, then `OrderDate` ascending.

Constraints

- Use `GROUP BY` and `HAVING`.
- Do not use window functions, CTEs, temporary tables, or create new database objects.
- Read-only query only; do not modify the data.
- Use `DataEngineeringPracticeDB_Lite` initially.

Submit your SQL query and the output from SSMS. I’ll review your attempt first, without giving away the solution or hints.

*/

SELECT
	O.CustomerID,
	O.OrderDate,
	O.TotalAmount,
	COUNT(*) AS DuplicateOrderCount,
	COUNT(*) - 1 AS DuplicateExcessCount
FROM Orders O
GROUP BY 
	O.CustomerID,
	O.OrderDate,
	O.TotalAmount
HAVING COUNT(*) > 1
ORDER BY DuplicateOrderCount DESC,
		O.CustomerID ASC,
		O.OrderDate ASC