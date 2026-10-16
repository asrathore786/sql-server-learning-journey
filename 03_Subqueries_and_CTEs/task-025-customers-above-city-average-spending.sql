/*

Task 025 — Customers Spending More Than Their City Average
First, save the SQL file in SSMS 2022 using the filename below.

Business requirement
The sales manager wants to identify customers whose total spending across all orders is greater than the average total spending of customers in the same city.
Use your existing PracticeDatabase tables: Customers and Orders.
Return these columns:
- CustomerID
- CustomerName
- City
- TotalCustomerSpending
- CityAverageSpending
Rules
1. Calculate each customer's total spending using SUM(Orders.TotalAmount).
2. Calculate the average of those customer totals separately for each city.
3. Include only customers whose total spending is strictly greater than their city's average.
4. Include all order statuses.
5. Customers without any orders should not be included.
6. Sort by City ascending, then TotalCustomerSpending descending.
Your challenge
Before writing SQL, identify the logical steps:
1. How will you calculate total spending per customer? -> Will Partition By customer ID will using window function
2. How will you calculate the average of customer totals per city? -> will group by cusotmer ID and CITY to get the aggregated average
3. How will you compare each customer's spending against their city's average? Will compare the total spending of cusotmer with the compare the average calculated using group by
You can use CTEs, subqueries, or window functions. Choose the approach you understand best.

*/


WITH TotalSpending AS
(
SELECT 
	c.CustomerID,
	c.CustomerName,
	c.city,
	SUM(o.totalAmount) AS TotalCustomerSpending
FROM customers c
INNER JOIN Orders o
	ON o.CustomerID = c.CustomerID
GROUP BY 
	c.CustomerID,
	c.CustomerName,
	c.city
)
,
CityAverage AS
(
SELECT 
	T.city,
	AVG(T.TotalCustomerSpending) AS CityAverageSpending
FROM TotalSpending T
LEFT JOIN Orders o
	ON o.CustomerID = T.CustomerID
GROUP BY T.city
)

SELECT 
	T.CustomerID,
	T.City,
	T.CustomerName,
	T.TotalCustomerSpending,
	C.CityAverageSpending
FROM TotalSpending T
LEFT JOIN CityAverage C
	ON C.City = T.City
WHERE T.TotalCustomerSpending > C.CityAverageSpending

