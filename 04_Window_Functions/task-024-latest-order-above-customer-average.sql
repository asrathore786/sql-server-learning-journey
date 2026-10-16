/*

Task 024 — Latest Order Above Customer Average
Business requirement
The sales team wants to identify customers whose most recent order amount is greater than their own average order amount.
Using your existing PracticeDatabase tables, Customers and Orders, write a SQL query that returns:
- CustomerID
- CustomerName
- LatestOrderDate
- LatestOrderAmount
- AverageOrderAmount
Rules
1. Calculate each customer's average order amount across all their orders.
2. Identify the most recent order date for each customer.
3. If a customer has multiple orders on that latest date, include all orders from that date.
4. Include all statuses: Completed, Pending, and Cancelled.
5. Return only the latest orders whose amount is strictly greater than the customer's average.
6. Sort the results by CustomerID.


What we are finding here in --> need to check the most recent order of customer must be greater with the average of customer order amount,
We need to find out the average of Total amount per customers,
We need to find the customers order amount based on recent order,
If there is multiple recent order then all order needs to be in date,
Then will compare the latest order amount with average and it should be greater than average.
Sort the order by CustomerID

*/


--SELECT * FROM orders o
--SELECT * FROM customers c
--SELECT * FROM OrderItems I

WITH CTE_LatestOrder AS
(
SELECT
	c.CustomerID,
	c.CustomerName,
	o.orderDate,
	MAX(o.orderDate) OVER (PARTITION BY c.customerID) AS LatestOrder,
	o.TotalAmount AS LatestOrderAmount
FROM Orders o
	INNER JOIN Customers c
		ON c.CustomerID = o.CustomerID
)
,
 CTE_AverageOrder AS
 (
SELECT 
	c1.customerID,
	AVG(o1.TotalAmount) AS AverageOrderAmount
FROM Orders o1
	INNER JOIN Customers c1
		ON c1.CustomerID = o1.CustomerID
GROUP BY c1.CustomerID
)

SELECT 
	CL.CustomerID,
	CL.CustomerName,
	CL.LatestOrderAmount,
	CL.LatestOrder,
	CA.AverageOrderAmount
FROM CTE_LatestOrder CL
INNER JOIN CTE_AverageOrder CA
	ON CL.CustomerID = CA.CustomerID
	AND CL.LatestOrderAmount > CA.AverageOrderAmount
	WHERE CL.LatestOrder =  CL.OrderDate