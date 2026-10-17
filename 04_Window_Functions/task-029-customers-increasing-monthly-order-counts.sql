/*

Task 029 — Customers with Increasing Monthly Order Counts

Business requirement
The banking analytics team wants to identify customers whose order activity is increasing over time.
Using PracticeDatabase, identify each customer’s consecutive active-month pairs where the customer placed more orders in the later month than in the previous active month.
Include only pairs where the two active months are exactly one calendar month apart. If a customer skips a month, do not compare the months on either side of that gap.
Count all orders regardless of status. Customers with no qualifying month pair should not appear.
Expected output
Column						Description
CustomerID					Customer identifier
CustomerName				Customer name
PreviousMonth				Earlier active month
CurrentMonth				Immediately following active month
PreviousMonthOrderCount		Number of orders in the earlier month
CurrentMonthOrderCount		Number of orders in the later month
OrderCountIncrease			Difference between the two monthly order counts
Sorting: CustomerID ascending, then PreviousMonth ascending.


Order Activity is increasing over time for each customer
Customer Placed more order than the previous month
This should be in pair of two months, if middle month skipped we need to exclude the customer

Example 
Customer 1
	JAN with 1 order
	FEB with 2 order 
- Customer 1 Include in result
Customer 2
	JAN with 1 order
	FEB with 2 order 
- Customer 2 does not Include in result
Customer 3
	JAN with 1 order
	MAR with 2 order 
- Customer 3 does not Include in result

Customer result should be order in customerID ASC and PreviousMonth ASC
*/

WITH CTE_CurrentMonth AS
(
SELECT 
	C.CustomerID,
	C.CustomerName,
	DATEFROMPARTS(YEAR(O.OrderDate), MONTH(O.OrderDate), 1) AS CurrentMonth,
	COUNT(O.OrderID) AS CurrentMonthOrderCount
FROM customers C
	INNER JOIN Orders O
		ON C.CustomerID = O.CustomerID
GROUP BY 
	C.CustomerID,
	C.CustomerName,
	DATEFROMPARTS(YEAR(O.OrderDate), MONTH(O.OrderDate), 1)
)
,
CTE_MonthlyOrder AS
(
SELECT
	CustomerID,
	CustomerName,
	CurrentMonth,
	CurrentMonthOrderCount,
	LAG(CurrentMonth) OVER(PARTITION BY CustomerID ORDER BY CurrentMonth) AS PreviousMonth,
	LAG(CurrentMonthOrderCount) OVER(PARTITION BY CustomerID ORDER BY CurrentMonth) AS PreviousMonthOrderCount
FROM CTE_CurrentMonth
)
SELECT 
	Active.CustomerID,
	Active.CustomerName,
	Active.CurrentMonth,
	Active.PreviousMonth,
	Active.CurrentMonthOrderCount,
	Active.PreviousMonthOrderCount,
	Active.CurrentMonthOrderCount-Active.PreviousMonthOrderCount AS OrderCountIncrease
FROM CTE_MonthlyOrder Active
WHERE DATEDIFF(MONTH,Active.PreviousMonth,Active.CurrentMonth) = 1
AND Active.PreviousMonthOrderCount < Active.CurrentMonthOrderCount
ORDER BY
    Active.CustomerID ASC,
    Active.PreviousMonth ASC;