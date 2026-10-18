/*

Task 030 — Month-over-Month Order Count Change
Business requirement
The analytics team wants to monitor month-over-month order activity for each customer.
Using PracticeDatabase, calculate the change in order count between each customer's current active month and their previous active month.
Include every customer-month row that has a previous active month, even if the previous month was not the immediately preceding calendar month. Identify the number of calendar months between the two active months so the team can distinguish consecutive activity from gaps.
Count all orders regardless of status.
Expected output
Column						Description
CustomerID					Customer identifier
CustomerName				Customer name
PreviousActiveMonth			Previous month in which the customer placed an order
CurrentActiveMonth			Current month in which the customer placed an order
PreviousMonthOrderCount		Order count in the previous active month
CurrentMonthOrderCount		Order count in the current active month
OrderCountChange			Current count minus previous count
CalendarMonthGap			Number of calendar months between the two active months
Sorting: CustomerID ASC, then CurrentActiveMonth ASC

-> Month Over Month Activity
1. We need to find the customer current month and previous month and need to check what was the order change from previous month.
2. If the previous month is not the preceding even though we have to include in result,
3. we need to find the gap between Two active month.
4. We need to get the order count change and calendar month gap as well.
6. Result need to be sort in ASC customerID, CurrentActiveMOnth ASC

*/


WITH Monthly_Order AS
(
SELECT 
	c.customerID,
	c.CustomerName,
	DATETRUNC(MONTH,O.OrderDate) AS CurrentActiveMonth,
	COUNT(o.OrderID) AS CurrentMonthOrderCount
FROM customers c
	INNER JOIN Orders O
		ON O.customerID = C.CustomerID
GROUP BY 
	c.customerID,
	c.CustomerName,
	DATETRUNC(MONTH,O.OrderDate)
)
,
Previous_Active_Month AS
(
SELECT 
	M.CustomerID,
	M.CustomerName,
	LAG(M.CurrentActiveMonth) OVER(PARTITION BY M.CustomerID ORDER BY M.CurrentActiveMonth) AS PreviousActiveMonth,
	M.CurrentActiveMonth,
	LAG(M.CurrentMonthOrderCount) OVER (PARTITION BY M.CustomerID ORDER BY M.CurrentActiveMonth) AS PreviousMonthOrderCount,
	M.CurrentMonthOrderCount
FROM Monthly_Order M
)


SELECT 
	P.CustomerID,
	P.CustomerName,				
	P.PreviousActiveMonth,			
	P.CurrentActiveMonth,		
	P.PreviousMonthOrderCount,		
	P.CurrentMonthOrderCount,		
	P.CurrentMonthOrderCount - P.PreviousMonthOrderCount AS OrderCountChange,			
	DATEDIFF(MONTH,P.PreviousActiveMonth,P.CurrentActiveMonth) AS CalendarMonthGap
FROM Previous_Active_Month P
WHERE P.PreviousActiveMonth IS NOT NULl
ORDER BY 
	P.CustomerID ASC, 
	P.CurrentActiveMonth ASC

/*

1. Original attempt
Your original query is preserved as submitted in this conversation. No changes were required.
2. Final reviewed query
This is your final query, unchanged:
WITH Monthly_Order AS
(
    SELECT
        C.CustomerID,
        C.CustomerName,
        DATETRUNC(MONTH, O.OrderDate) AS CurrentActiveMonth,
        COUNT(O.OrderID) AS CurrentMonthOrderCount
    FROM Customers C
    INNER JOIN Orders O
        ON O.CustomerID = C.CustomerID
    GROUP BY
        C.CustomerID,
        C.CustomerName,
        DATETRUNC(MONTH, O.OrderDate)
),
Previous_Active_Month AS
(
    SELECT
        M.CustomerID,
        M.CustomerName,
        LAG(M.CurrentActiveMonth) OVER (
            PARTITION BY M.CustomerID
            ORDER BY M.CurrentActiveMonth
        ) AS PreviousActiveMonth,
        M.CurrentActiveMonth,
        LAG(M.CurrentMonthOrderCount) OVER (
            PARTITION BY M.CustomerID
            ORDER BY M.CurrentActiveMonth
        ) AS PreviousMonthOrderCount,
        M.CurrentMonthOrderCount
    FROM Monthly_Order M
)
SELECT
    P.CustomerID,
    P.CustomerName,
    P.PreviousActiveMonth,
    P.CurrentActiveMonth,
    P.PreviousMonthOrderCount,
    P.CurrentMonthOrderCount,
    P.CurrentMonthOrderCount - P.PreviousMonthOrderCount
        AS OrderCountChange,
    DATEDIFF(
        MONTH,
        P.PreviousActiveMonth,
        P.CurrentActiveMonth
    ) AS CalendarMonthGap
FROM Previous_Active_Month P
WHERE P.PreviousActiveMonth IS NOT NULL
ORDER BY
    P.CustomerID ASC,
    P.CurrentActiveMonth ASC;

3. Principle learned
Use LAG() when you need to compare the current row with the previous available row within a group.
For this exercise:
- PARTITION BY CustomerID keeps each customer's history separate.
- ORDER BY CurrentActiveMonth defines chronological order.
- LAG() retrieves the previous active month's date and order count.
- DATEDIFF() calculates the calendar-month gap.
- Subtracting the counts gives the month-over-month change.
Remember: LAG() returns the previous available row, not necessarily the previous calendar month.

4. Validation checks
After running the query in SSMS, check these cases:
Test case	                            Expected behavior
Customer's first active month	        Excluded because there is no previous active month
January followed by February	        CalendarMonthGap = 1
January followed by March	            CalendarMonthGap = 2
Current count exceeds previous count	Positive OrderCountChange
Current count equals previous count	    OrderCountChange = 0
Current count is lower	                Negative OrderCountChange
Multiple customers	                    Previous-month comparisons remain within each customer

*/