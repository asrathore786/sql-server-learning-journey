/*
Task 027 — Customers With Consecutive Monthly Orders
An e-commerce company wants to identify customers who placed orders in at least two consecutive calendar months.
Using the existing Customers and Orders tables in PracticeDatabase, return each customer who had at least one order in a month and at least one order in the immediately following month.
Consider all order statuses. Multiple orders by the same customer within a month should count as activity in that month, not as separate months.
Return one row per qualifying customer and consecutive-month pair. If a customer has orders in January, February, and March, return both the January–February pair and the February–March pair.

Required output columns:
Column					Description
CustomerID				Customer identifier
CustomerName			Customer name
FirstMonth				First active calendar month, represented by its first day
NextMonth				Immediately following active calendar month
FirstMonthOrderCount	Number of orders in the first month
NextMonthOrderCount		Number of orders in the following month
Sorting: CustomerID ASC, then FirstMonth ASC.

--> We need to identify the customers who order in consicutive month,

How i approach this query, i will first identify the customer with january month then identify the customer in Feburary.If we identify the febuary then we need to check customers in March. and so on
Then we need to check when if customer has order in current month and we need to check same customer should order in next immediate month.
While generating output we need to identify the no. of order in current and immediate next month
Result should be sorted in ID ASC and FirstMonth ASC
*/


WITH CTE_CurrentMonth AS
(
SELECT 
	C.CustomerID,
	C.CustomerName,
	DATETRUNC(month,O.OrderDate) FirstMonth,
	COUNT(O.orderDate) AS OrderCount
FROM Customers C
INNER JOIN Orders O
	ON O.CustomerID = C.CustomerID
GROUP BY 
	C.CustomerID,
	C.CustomerName,
	DATETRUNC(month,O.OrderDate)
)

SELECT 
	C1.CustomerID,
	C1.CustomerName,
	C1.FirstMonth,
	C2.FirstMonth AS NextMonth,
	C1.OrderCount AS FirstMonthOrderCount,
	C2.OrderCount AS NextMonthOrderCount
FROM CTE_CurrentMonth C1
INNER JOIN CTE_CurrentMonth C2
	ON C1.CustomerID = C2.CustomerID
	AND DATEDIFF(MONTH, C1.FirstMonth , C2.FirstMonth) = 1
--WHERE C2.FirstMonth IS NOT NULl
ORDER BY 
	C1.CustomerID ASC,
	C1.FirstMonth
