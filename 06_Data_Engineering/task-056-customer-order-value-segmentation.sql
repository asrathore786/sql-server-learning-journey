/*

## Task 056 — Customer Order Value Segmentation

Advanced

SQL Server 2022

Filename: `task-056-customer-order-value-segmentation.sql`

Folder: `06_Data_Engineering`

Database: `DataEngineeringPracticeDB_Lite`

Table: `dbo.Orders`

### Business requirement

The business wants to segment customers based on the total monetary value of their orders to identify high-value customers and prioritize retention efforts.

Prepare a report containing customers who have placed at least one order. For each customer, calculate their total order value and assign a segment according to the following business rules:

- Premium: Total order value is greater than ₹20,000.
- Standard: Total order value is between ₹10,000 and ₹20,000, inclusive.
- Basic: Total order value is greater than ₹0 but less than ₹10,000.
- No Value: Total order value is ₹0.

The report must also show each customer's total number of orders, average order value, first order date, and most recent order date.

### Expected output

| Column                 | Description              |
| ---------------------- | ------------------------ |
| `CustomerID`           | Customer identifier      |
| `TotalOrders`          | Number of orders placed  |
| `TotalOrderValue`      | Sum of order amounts     |
| `AverageOrderValue`    | Average amount per order |
| `FirstOrderDate`       | Earliest order date      |
| `LastOrderDate`        | Most recent order date   |
| `CustomerValueSegment` | Assigned value segment   |

Sorting: `TotalOrderValue` descending, then `CustomerID` ascending.

Important: Use the order amounts recorded in `dbo.Orders`. Follow the stated boundaries exactly.

Your task is to write the SQL query independently. I won't provide hints, identify the grain, suggest SQL functions, or reveal the solution before your attempt.

Run your query in SSMS and share the SQL first. I'll review your logic before asking you to validate the output.

*/


WITH Customer_Order_Details AS
(
SELECT
	O.customerID,
	COUNT(O.OrderId) AS TotalOrders,
	AVG(O.TotalAmount) AS AverageOrderValue,
	SUM(O.TotalAmount) AS TotalOrderValue,
	MIN(O.OrderDate) AS FirstOrderDate,
	MAX(O.ORderDate) AS LastOrderDate
FROM Orders O
GROUP BY O.CustomerID
)

SELECT
	C.CustomerID,
	C.TotalOrders,
	ROUND(C.TotalOrderValue,0),
	CAST(C.AverageOrderValue AS DECIMAL(10,2)),
	C.FirstOrderDate,
	C.LastOrderDate,
	CASE
		WHEN C.TotalOrderValue = 0 THEN 'No Value'
		WHEN C.TotalOrderValue > 0 AND C.TotalOrderValue < 10000 THEN 'Basic'
		WHEN C.TotalOrderValue BETWEEN 10000 AND 20000 THEN 'Standard'
		WHEN C.TotalOrderValue > 20000 THEN 'Premium'
	END AS CustomerValueSegment
FROM Customer_Order_Details C
ORDER BY C.TotalOrderValue DESC, C.CustomerID ASC

--- Premium: Total order value is greater than ₹20,000.
--- Standard: Total order value is between ₹10,000 and ₹20,000, inclusive.
--- Basic: Total order value is greater than ₹0 but less than ₹10,000.
--- No Value: Total order value is ₹0.