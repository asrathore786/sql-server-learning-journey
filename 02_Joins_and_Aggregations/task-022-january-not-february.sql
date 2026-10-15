/*
SQL Practice — Task 22
Intermediate → Advanced
SQL Server 2022

Business requirement
The sales manager wants to find customers who have placed at least one order in January 2026 but did not place any orders in February 2026.
Display:
- CustomerID
- CustomerName
- JanuaryOrderCount
- JanuaryTotalAmount
Rules
1. Consider orders from January 1–31, 2026.
2. Exclude customers who placed even one order in February 2026.
3. Count all January orders, regardless of status.
4. Calculate the sum of January order amounts, regardless of status.
5. Return one row per qualifying customer.
Your task
Before writing SQL, explain in your own words:
1. What exactly must the query find? --> We need to find the customers who placed on order in january 2026 but should be no order in feburary 2026, if any order place in both month then these customer will be exclude from the result
2. Why is checking January alone insufficient? --> because there is a possibility when we check customer order in januray he order but in case he made order in feburay then this customer must be excluded as per business requirement
3. How would you approach solving this requirement? --> 

First i will check who all placed an order in january 2026
then i will check who all customer place order in feb 2026
Once we find out both then we check customer appeared in Jan 2026 should not be available in Feb 2026
then at last we need to calcuate the total of customer order with january 2026 order

*/


WITH JanuaryOrder AS
(
SELECT 
	c.CustomerID,
	c.CustomerName,
	COUNT(*) JanuaryOrderCount,
	SUM(o.totalAmount) JanuaryTotalAmount
FROM customers c
LEFT JOIN orders o
	ON o.CustomerID = c.CustomerID 
WHERE o.OrderDate >= '20260101' AND o.OrderDate < '20260201'
GROUP BY 
	c.CustomerID,
	c.CustomerName
),
FeburaryOrder AS
(
SELECT 
	c.CustomerID,
	c.CustomerName
FROM customers c
LEFT JOIN orders o
	ON o.CustomerID = c.CustomerID 
WHERE o.OrderDate >= '20260201' AND o.OrderDate < '20260301'
)

SELECT * 
FROM JanuaryOrder J
WHERE NOT EXISTS
	( SELECT 1 FROM FeburaryOrder F
		WHERE J.CustomerID = F.CustomerID)
