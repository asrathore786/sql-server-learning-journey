/*

SQL Practice — Task 21
Intermediate
SQL Server 2022
PracticeDatabase

Business requirement
The sales manager wants to identify customers whose individual order amount is greater than that customer's own average order amount.
Display:
- CustomerID
- CustomerName
- OrderID
- TotalAmount
- CustomerAverageOrderAmount
Rules
1. Calculate the average separately for each customer.
2. Include all order statuses.
3. Return only orders strictly greater than their customer's average.
4. If multiple orders qualify for one customer, return all of them.
5. Do not aggregate the final output into one row per customer.
Your task
Before writing SQL, explain:
1. What exactly must the query find? --> We need to find the customers who have grater order amount then their own Average orders 
2. How is this average different from Task 20's overall average? --> In 20 we find average based on all order irrespective of customer check, here we need to take single cusotmer order and compare with customer own orders average if customer having two orders then take the average of both the order if greater then retun otherwise exclude
3. How would you approach solving this requirement? 

First i will aggregate the customer to calculate the average of order group by customers.
Then will compare with each customer order with the average if the customer order is greater then will keep it otherwise will exclude, if multiple records then keep them both no aggregation need while returing result

*/


WITH CustomerAverage AS
(
SELECT
	c1.customerID,
	AVG(o1.TotalAmount) AS CustomerAverageOrderAmount
FROM customers c1
INNER JOIN orders o1
	ON o1.customerID = c1.customerID
GROUP BY c1.CustomerID
)	

SELECT
	c.CustomerID,
	c.CustomerName,
	o.OrderID,
	o.TotalAmount,
	CA.CustomerAverageOrderAmount
FROM customers c
INNER JOIN orders o
	ON o.customerID = c.customerID
INNER JOIN CustomerAverage CA
	ON CA.CustomerID = c.CustomerID
	AND o.TotalAmount > CA.CustomerAverageOrderAmount
