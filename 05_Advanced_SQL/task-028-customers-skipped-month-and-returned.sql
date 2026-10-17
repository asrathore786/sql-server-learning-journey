/*

Task 028 — Customers Who Skipped a Month and Returned

Business requirement
The business wants to identify customers who placed orders in one calendar month, did not place any orders in the immediately following month, and then returned to place at least one order in the month after that.
For example, if a customer ordered in January, did not order in February, and ordered again in March, that customer qualifies.
Consider all order statuses. Multiple orders within a month count as activity in that month, not as separate months.
Required output columns
Column					Description
CustomerID				Customer's unique ID
CustomerName			Customer's name
LastActiveMonth			First day of the month before the gap
SkippedMonth			First day of the month with no orders
ReturnMonth				First day of the month the customer returned
LastActiveOrderCount	Number of orders in the last active month
ReturnOrderCount		Number of orders in the return month
Sorting: CustomerID ASC, then LastActiveMonth ASC.
Rules
- Use the existing PracticeDatabase tables.
- Use calendar months, including the year.
- The skipped month must be exactly one month after LastActiveMonth.
- The return month must be exactly one month after SkippedMonth.
- Return one row per qualifying customer and active-month/gap/return sequence.
- Do not count the missing month's orders; there should be none.
Your task
Write the SQL query independently in SSMS. Save it using the filename above.


We need to identify the customers who place one order in current month and not place in immediate next month, but again placed an order in immediate after next month

The skipped month will be one month only.

First will identify the first month of the customer who ordered in current month
then will check id customer order in next month then they must be exlcude
If the customer again placed an oredr after skipped month then these cusotmers must be considered in result,
Apart from this we need to calculate the count of both month as he dont have order in skipped month then no order count is required
When we get result then it should be sorted with CustomerID ASC, then LastActiveMonth ASC.

*/

WITH CTE_MonthlyOrder AS
(
SELECT 
	o.CustomerID,
	DATEFROMPARTS(YEAR(o.orderDate),MONTH(o.OrderDate),1) AS ActiveMonth,
	COUNT(O.orderID) AS ActiveMonthOrderCount
FROM orders o
GROUP BY 
	o.CustomerID,
	DATEFROMPARTS(YEAR(o.orderDate),MONTH(o.OrderDate),1)
)
SELECT 
	c.customerID,
	c.CustomerName,
	Active.ActiveMonth AS LastActiveMonth,
	DATEADD(MONTH, 1, active.ActiveMonth) AS SkippedMonth,
	Returned.ActiveMonth AS ReturnMonth,
	Active.ActiveMonthOrderCount AS LastActiveOrderCount,
	Returned.ActiveMonthOrderCount AS ReturnOrderCount
FROM CTE_MonthlyOrder Active
INNER JOIN CTE_MonthlyOrder Returned
	ON Returned.CustomerID = Active.CustomerID
	AND Returned.ActiveMonth = DATEADD(Month,2,Active.ActiveMonth)
INNER JOIN Customers c
	ON c.customerID = Active.CustomerID
WHERE 
	NOT EXISTS
		(
		SELECT 1
	FROM CTE_MonthlyOrder skipped
	WHERE skipped.CustomerID = active.CustomerID
	  AND skipped.ActiveMonth = DATEADD(MONTH, 1, active.ActiveMonth)
	)
ORDER BY Active.CustomerID ASC, Active.ActiveMonth