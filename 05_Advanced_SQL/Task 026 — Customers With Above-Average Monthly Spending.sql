/*

Business requirement

An e-commerce company wants to identify customers whose total spending in a particular month exceeds the average monthly spending of customers who placed orders in that same month.
Use the existing Customers and Orders tables in PracticeDatabase.
For each customer and calendar month, calculate the customer's total order amount. Then identify customers whose monthly total is strictly greater than that month's average customer spending.
Include all order statuses. Exclude customers who did not place an order during the relevant month.

Expected output				columns
Column						Description
CustomerID					Unique customer identifier
CustomerName				Customer name
City						Customer's city
OrderMonth					Month represented by the result, preferably the first day of that month
MonthlyCustomerSpending		Customer's total spending in that month
MonthlyAverageSpending		Average customer spending for that month
Sorting: OrderMonth ASC, then MonthlyCustomerSpending DESC, then CustomerID ASC.

*/


WITH CustomerSpending AS
(
SELECT 
	c.CustomerID,
	c.CustomerName,
	c.City,
	DATETRUNC(month,o.orderDate) AS OrderMonth,
	SUM(o.totalAmount) AS MonthlyCustomerSpending
FROM Customers c
INNER JOIN orders o
	ON c.CustomerID = o.CustomerID
GROUP BY 
	c.CustomerID,
	c.CustomerName,
	DATETRUNC(month,o.orderDate),
	c.City

),

AverageSpending AS
(
SELECT 
	DATETRUNC(month,S.OrderMonth) AS OrderMonthNew,
	AVG(S.MonthlyCustomerSpending) AS MonthlyAverageSpending
FROM CustomerSpending S
GROUP BY DATETRUNC(month,S.OrderMonth) 
)

SELECT 
	C.CustomerID,
	C.CustomerName,
	C.City,
	DATETRUNC(month,C.OrderMonth),
	C.MonthlyCustomerSpending,
	A.MonthlyAverageSpending
FROM CustomerSpending C
LEFT JOIN AverageSpending A
	ON A.OrderMonthNew = C.OrderMonth
WHERE C.MonthlyCustomerSpending > A.MonthlyAverageSpending
ORDER BY C.OrderMonth ASC, C.MonthlyCustomerSpending DESC, C.CustomerID ASC