/*

Task 031 — Customer Monthly Order Activity Classification

Business requirement
The operations team wants to classify each customer's monthly ordering activity to identify changes in purchasing behavior.
Using PracticeDatabase, write a SQL query that:
1. Aggregates orders into one row per customer per active month.
2. Calculates each customer's order count for that month.
3. Uses the previous active month to compare monthly order counts, even when a calendar month is missing.
4. Classifies each comparison into one of these categories:
   - New Activity — the customer has no previous active month.
   - Increased — the current month's order count is greater than the previous active month's count.
   - Decreased — the current month's order count is less than the previous active month's count.
   - Unchanged — both counts are equal.
5. Includes the order-count difference and the calendar-month gap.
6. Includes all customers who have at least one order, including each customer's first active month.
7. Sorts the result by CustomerID ascending and CurrentActiveMonth ascending.
Count all orders regardless of their status.
Expected output columns
Column						Description
CustomerID					Customer identifier
CustomerName				Customer name
PreviousActiveMonth			Previous month in which the customer placed an order; NULL for the first active month
CurrentActiveMonth			Month currently being analyzed
PreviousMonthOrderCount		Order count in the previous active month; NULL for the first active month
CurrentMonthOrderCount		Order count in the current active month
OrderCountChange			Current count minus previous count; NULL for the first active month
CalendarMonthGap			Number of calendar-month boundaries between the two months; NULL for the first active month
ActivityClassification		New Activity, Increased, Decreased, or Unchanged

Approcah to solve the TASK :
--> Will identify all the customer from table who placed at least one order in order table.
Then will find the order count of each customer for per month
Once we find out month then will perform some transformation(USING LAG or SELF_JOIN) to get the previous month and Previous month order count,
Once we have all the information then will mark the change in order as belowL
	Previous Order count is NULL and in current we have order then marked as New Activity,
	If Current Month Order is greater than previous then marked as Increased
	If Current Month order is less than previous then marked as decreases
	If both the count is equal marked as Unchanged
Apart from the above we need to show the order difference and month gap
We need exclude we never have order anything
Result should be sort by Customer ID ASC and CurrentActiveMonth ASC

*/

WITH CTE_CURRENT_MONTH AS
(
SELECT
	C.CustomerID,
	C.CustomerName,
	DATETRUNC(MONTH,O.OrderDate) CurrentMonth,
	COUNT(O.OrderID) AS CurrentMonthOrderCount
FROM Customers C
INNER JOIN Orders O
	ON O.CustomerID = C.CustomerID
GROUP BY 
	C.CustomerID,
	C.CustomerName,
	DATETRUNC(MONTH,O.OrderDate)
),
PREVIOUS_MONTH AS
(
SELECT
	C.CustomerID,
	C.CustomerName,
	C.CurrentMonth,
	C.CurrentMonthOrderCount,
	LAG(C.CurrentMonth) OVER(PARTITION BY C.customerID ORDER BY C.CurrentMonth) AS PreviousMonth,
	LAG(C.CurrentMonthOrderCount) OVER(PARTITION BY C.customerID ORDER BY C.CurrentMonth) AS PreviousMonthOrderCount
FROM CTE_CURRENT_MONTH C
)
SELECT 
	Previous.CustomerID,
	Previous.CustomerName,
	Previous.PreviousMonth,
	Previous.CurrentMonth,
	Previous.PreviousMonthOrderCount,
	Previous.CurrentMonthOrderCount,
	Previous.CurrentMonthOrderCount - Previous.PreviousMonthOrderCount AS OrderCountChange,
	DATEDIFF(MONTH,Previous.PreviousMonth,Previous.CurrentMonth) AS CalendarMonthGap,
	CASE
		WHEN Previous.PreviousMonth IS NULL THEN 'New Activity'
		WHEN Previous.CurrentMonthOrderCount < Previous.PreviousMonthOrderCount THEN 'Decreased'
		WHEN Previous.CurrentMonthOrderCount > Previous.PreviousMonthOrderCount THEN 'Increased'
		ELSE 'Unchanged'
	END AS ActivityClassification
FROM PREVIOUS_MONTH Previous
ORDER BY 
	Previous.CustomerID ASC,
	Previous.CurrentMonth ASC