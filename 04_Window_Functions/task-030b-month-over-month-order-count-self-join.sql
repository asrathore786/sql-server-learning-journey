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
	COUNT(o.OrderID) AS CurrentMonthOrderCount,
	DENSE_RANK() OVER(PARTITION BY c.customerID ORDER BY DATETRUNC(MONTH,O.OrderDate) ASC) AS RNK
FROM customers c
	INNER JOIN Orders O
		ON O.customerID = C.CustomerID
GROUP BY 
	c.customerID,
	c.CustomerName,
	DATETRUNC(MONTH,O.OrderDate)
)
SELECT 
	Active.CustomerID,
	Active.CustomerName,
	Active.CurrentActiveMonth,
	Previous.CurrentActiveMonth AS PreviousActiveMonth,
	Active.CurrentMonthOrderCount,
	Previous.CurrentMonthOrderCount AS PreviousMonthOrderCount,
	Active.CurrentMonthOrderCount - Previous.CurrentMonthOrderCount AS OrderCountChange,
	DATEDIFF(MONTH,Previous.CurrentActiveMonth,Active.CurrentActiveMonth) AS CalendarMonthGap
FROM Monthly_Order Active
INNER JOIN Monthly_Order Previous
	ON Active.CustomerID = Previous.CustomerID
	AND Active.RNK - Previous.RNK = 1
ORDER BY 
	Active.CustomerID ASC,
	Active.CurrentActiveMonth ASC


/*
Task 030B — Month-over-Month Comparison Using Self-Join

File: 04_Window_Functions/task-030b-month-over-month-order-count-self-join.sql

Original attempt
You joined every earlier month using:
AND Active.CurrentActiveMonth > Previous.CurrentActiveMonth

This generated multiple matches for each active month.

Final query

WITH Monthly_Order AS
(
    SELECT
        C.CustomerID,
        C.CustomerName,
        DATETRUNC(MONTH, O.OrderDate) AS CurrentActiveMonth,
        COUNT(O.OrderID) AS CurrentMonthOrderCount,
        DENSE_RANK() OVER
        (
            PARTITION BY C.CustomerID
            ORDER BY DATETRUNC(MONTH, O.OrderDate)
        ) AS RNK
    FROM Customers C
    INNER JOIN Orders O
        ON O.CustomerID = C.CustomerID
    GROUP BY
        C.CustomerID,
        C.CustomerName,
        DATETRUNC(MONTH, O.OrderDate)
)
SELECT
    Active.CustomerID,
    Active.CustomerName,
    Previous.CurrentActiveMonth AS PreviousActiveMonth,
    Active.CurrentActiveMonth,
    Previous.CurrentMonthOrderCount AS PreviousMonthOrderCount,
    Active.CurrentMonthOrderCount,
    Active.CurrentMonthOrderCount
        - Previous.CurrentMonthOrderCount AS OrderCountChange,
    DATEDIFF
    (
        MONTH,
        Previous.CurrentActiveMonth,
        Active.CurrentActiveMonth
    ) AS CalendarMonthGap
FROM Monthly_Order Active
INNER JOIN Monthly_Order Previous
    ON Active.CustomerID = Previous.CustomerID
    AND Active.RNK - Previous.RNK = 1
ORDER BY
    Active.CustomerID ASC,
    Active.CurrentActiveMonth ASC;

Principle learned: Use DENSE_RANK() to identify sequential active-month records, then self-join on adjacent ranks. Use DATEDIFF() separately to measure the calendar gap.
Validation checks
- Each output row has the same customer in both records.
- The rank difference is exactly one.
- A month with no orders does not prevent comparison between consecutive active months.
- The order-count change equals current count minus previous count.
- The first active month is excluded.
- The output is sorted by customer and current active month.

*/