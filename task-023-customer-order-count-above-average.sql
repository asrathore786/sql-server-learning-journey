/*

Task 23 — Customer Order Analysis
Intermediate
SQL Server 2022

Business requirement
The sales manager wants to identify customers who have placed more orders than the average number of orders placed by customers who have at least one order.
Display:
- CustomerID
- CustomerName
- OrderCount
Rules
1. Count all orders for each customer, regardless of status.
2. Calculate the average number of orders per ordering customer.
3. Return customers whose order count is strictly greater than that average.
4. Return one row per qualifying customer.
Your task
Before writing SQL, explain:
1. What exactly must the query find? -> In this query we are focusing on customers order count we need to check order count of each customer should be more than no. of order where customer placed at least one order
2. Should customers with zero orders be included when calculating the average? Why? -> No, as question is saying we need to check only average who have placed at least one order customer with 0 order must be excluded
3. How would you approach solving this requirement?

first will check for per customer order count from orders table
then will filter all customers who please at least one order
then will take the average of customers order and compare if 1st result count is more than 2nd result then will display those customers in result

*/


WITH OrderCount AS
(
SELECT 
	c.CustomerID,
	c.CustomerName,
	COUNT(o.customerID) AS CustomerOrderCount
FROM orders o
INNER JOIN customers c
	ON c.CustomerID = o.CustomerID
GROUP BY 
	c.CustomerID,
	c.CustomerName
)
SELECT 
	O1.CustomerID,
	O1.CustomerName,
	O1.CustomerOrderCount AS OrderCount
FROM OrderCount O1
WHERE O1.CustomerOrderCount > ( SELECT AVG(CAST(o.customerOrderCount AS DECIMAL (10,2))) FROM OrderCount o )