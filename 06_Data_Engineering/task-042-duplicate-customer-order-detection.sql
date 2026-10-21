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

/*

✅ Task 042 — Successfully validated.

Your SSMS output matches the expected result exactly.

### Result verification

| Check                             | Expected   | Actual     | Status |
| --------------------------------- | ---------- | ---------- | ------ |
| Duplicate group count             | 2 orders   | 2 orders   | Pass   |
| Excess duplicates                 | 1          | 1          | Pass   |
| Matching customer                 | Customer 1 | Customer 1 | Pass   |
| Matching order date               | 2026-10-20 | 2026-10-20 | Pass   |
| Matching amount                   | ₹500.00    | ₹500.00    | Pass   |
| Non-duplicate ₹700 order excluded | Yes        | Yes        | Pass   |

### Final query for your repository

Filename: `task-042-duplicate-customer-order-detection.sql`

Folder: `06_Data_Engineering`

```

USE DataEngineeringPracticeDB_Lite;
GO

SELECT
    O.CustomerID,
    O.OrderDate,
    O.TotalAmount,
    COUNT(*) AS DuplicateOrderCount,
    COUNT(*) - 1 AS DuplicateExcessCount
FROM dbo.Orders AS O
GROUP BY
    O.CustomerID,
    O.OrderDate,
    O.TotalAmount
HAVING COUNT(*) > 1
ORDER BY
    DuplicateOrderCount DESC,
    O.CustomerID ASC,
    O.OrderDate ASC;

```

### What this task taught you

- `GROUP BY` defines the attributes that determine whether records belong to the same group.
- `COUNT(*)` counts every row in a group.
- `HAVING COUNT(*) > 1` filters out groups that are not duplicates.
- `COUNT(*) - 1` calculates the number of excess records beyond the first occurrence.

The critical lesson from your attempts: do not include a unique identifier such as `OrderID` in the duplicate grouping when the business rule defines duplicates using other attributes.

### Git commands

After saving the query in the specified folder, run these commands from your repository root:

```

git status
git add "06_Data_Engineering/task-042-duplicate-customer-order-detection.sql"
git commit -m "Add Task 042 duplicate order detection"
git push origin main

```

Task 042 is complete. Your Lite database now contains three test orders (`9511–9513`) used for validation; retain them for future exercises or remove them when you no longer need this test case.

*/