SQL Practice — Task 19
Difficulty: Intermediate
Database: PracticeDatabase
Tables: Customers, Orders
Business requirement
The management team wants to identify customers who have placed at least one order with a total amount greater than every order placed by customer Amit.
Display the following columns:
- CustomerID
- CustomerName
- OrderID
- TotalAmount
Requirements:
1. Return the customer's qualifying orders, not just the customer names.
2. Compare each order against all orders placed by Amit.
3. Include all order statuses.
4. If a customer has multiple qualifying orders, display each one.
5. Do not include Amit's own orders.
Your task
Before writing SQL, explain in your own words:
1. What exactly must the query find?
2. What does “greater than every order placed by Amit” mean?
3. How would you approach solving this requirement?


explain in your own words:
1. What exactly must the query find? --> We need customer who have place at least one order and and order amount must be greater than every order done by Amit
2. What does “greater than every order placed by Amit” mean? --> With example, if AMIT please two order then we need to check all other customer Total amount with Amit Each order Amount and it should be greater
3. How would you approach solving this requirement? --> 

1st i will calcaulte the Total Amount(FieldName) of each customer who have placed 1 order (From order table ) will use LEFT join as we need customers in output, along with the order status
2nd, after calucalting total amount will check Amits order amounts
3rd, Now i will compare other qualified customers order amount with Amit order, if multiple qualified order then will display All 

Will create 2 CTE and at the end will combine both CTE to compare the orders if and kept only matching record

*/


SELECT 
	c.CustomerID,
	c.CustomerName,
	o.OrderID,
	o.TotalAmount
FROM orders o
INNER JOIN customers c
	ON c.CustomerID = o.CustomerID
WHERE TotalAmount > ALL (SELECT TotalAmount FROM orders o1
						LEFT JOIN customers c1
							ON c1.CustomerID = o1.CustomerID
						WHERE c1.CustomerName = 'AMIT')
					AND c.CustomerName != 'AMIT'
