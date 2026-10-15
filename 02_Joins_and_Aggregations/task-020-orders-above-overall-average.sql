/*

SQL Practice — Task 20
Intermediate
SQL Server 2022
PracticeDatabase

Business requirement
The management team wants to identify customers who have placed at least one order with an amount greater than the average order amount across all orders in the database.
Display these columns:
- CustomerID
- CustomerName
- OrderID
- TotalAmount
- AverageOrderAmount
Rules
1. Calculate the average using all orders in the Orders table.
2. Compare each individual order against that average.
3. Include all order statuses.
4. Return every qualifying order, not just one order per customer.
5. Do not aggregate the orders by customer.
Your task
Before writing SQL, explain these three things in your own words:
1. What exactly must the query find? --> Customer must placed and order and his order amount should be greater than average of all customers
2. Which orders should be included in the average calculation? - Average of all orders 
3. How would you approach solving this requirement? - 
Will find the customer order then will compare with All order average, if customer order amount is greater than average then display result with customer name, customer ID, order ID, total amount and average order Amount

*/

WITH AverageAmount AS
(
SELECT
	AVG(o1.TotalAmount) AverageTotalAmount
FROM orders o1
)

SELECT 
	c.CustomerID,
	c.CustomerName,
	o.OrderID,
	o.TotalAmount,
	A.AverageTotalAmount
FROM orders o
INNER JOIN customers c
	ON c.CustomerID = o.CustomerID
CROSS JOIN AverageAmount A
WHERE o.TotalAmount> A.AverageTotalAmount
