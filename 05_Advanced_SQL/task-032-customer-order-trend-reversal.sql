/*

Task 032 — Customer Order Trend Reversal

Business requirement
The banking analytics team wants to identify customers whose monthly order activity first increased and then decreased in their next active month. This may help identify customers whose purchasing activity is beginning to weaken.
Using PracticeDatabase, write a SQL query that identifies every instance where a customer's order count increased from one active month to the next, then decreased in the following active month.
For example:
Active month		Order count			Interpretation
January					1				Starting month
February				3				Increased
March					2				Decreased — trend reversal found
May						4				Increased again
For this customer, February is the peak month in the identified pattern: January → February increased, then February → March decreased. The missing April does not matter because comparisons use consecutive active months.
Requirements
1. Aggregate orders to one row per customer per active month.
2. Compare each active month with the previous active month.
3. Identify three consecutive active-month records where:
   - The second month's order count is greater than the first month's.
   - The third month's order count is less than the second month's.
4. Return the customer, all three active months, their respective order counts, the increase amount, the decrease amount, and both calendar-month gaps.
5. Count all orders regardless of status.
6. Exclude customers who do not have enough active months to form the pattern.
7. Sort by CustomerID ascending and the third active month ascending.
Expected output columns:
Column						Description
CustomerID					Customer identifier
CustomerName				Customer name
FirstActiveMonth			Month before the increase
SecondActiveMonth			Month where the order count increased
ThirdActiveMonth			Month where the order count decreased
FirstMonthOrderCount		Count in the first month
SecondMonthOrderCount		Count in the second month
ThirdMonthOrderCount		Count in the third month
OrderCountIncrease			Second count minus first count
OrderCountDecrease			Second count minus third count
FirstCalendarMonthGap		Gap from first to second month
SecondCalendarMonthGap		Gap from second to third month

How to Approach this Task:

1. first we need to check the first active month where customer placed an order
2. 2nd we need to check does his/her previous month order count is increased with current month order, if yes then we consider this as continue customers,
3. 3rd will check for the next month if his/her order in this month, order ccount should be descreased, if yes this is the customer we are looking for
4. for all we need to find the order count, then calculate the order decrease and increase count along with month gap
5. result should be sorted with CustomerID ascending and the third active month ascending

*/

WITH CTE_FirstMonth AS
(
SELECT 
	C.CustomerID,
	C.CustomerName,
	DATETRUNC(MONTH,O.orderDate) AS FirstActiveMonth,
	COUNT(O.orderID) AS FirstMonthOrderCount
FROM Customers C
	INNER JOIN Orders O
		ON O.CustomerID = C.CustomerID
GROUP BY
	C.CustomerID,
	C.CustomerName,
	DATETRUNC(MONTH,O.orderDate)
)
,
CTE_SecondMonth AS
(
SELECT 
	C.CustomerID,
	C.CustomerName,
	C.FirstActiveMonth,
	C.FirstMonthOrderCount,
	LEAD(C.FirstActiveMonth, 1) OVER(PARTITION BY C.CustomerID ORDER BY C.FirstActiveMonth) AS SecondActiveMonth,
	LEAD(C.FirstMonthOrderCount, 1, 0) OVER(PARTITION BY C.CustomerID ORDER BY C.FirstActiveMonth) AS SecondMonthOrderCount,
	LEAD(C.FirstActiveMonth, 2) OVER(PARTITION BY C.CustomerID ORDER BY C.FirstActiveMonth) AS ThirdActiveMonth,
	LEAD(C.FirstMonthOrderCount, 2, 0) OVER(PARTITION BY C.CustomerID ORDER BY C.FirstActiveMonth) AS ThirdMonthOrderCount
FROM CTE_FirstMonth C
)

SELECT
	M.CustomerID,			
	M.CustomerName,			
	M.FirstActiveMonth,		
	M.SecondActiveMonth,		
	M.ThirdActiveMonth,		
	M.FirstMonthOrderCount,	
	M.SecondMonthOrderCount,	
	M.ThirdMonthOrderCount,	
	M.SecondMonthOrderCount - M.FirstMonthOrderCount AS OrderCountIncrease,		
	M.SecondMonthOrderCount - M.ThirdMonthOrderCount AS OrderCountDecrease,		
	DATEDIFF(MONTH,M.FirstActiveMonth,M.SecondActiveMonth) AS FirstCalendarMonthGap,	
	DATEDIFF(MONTH,M.SecondActiveMonth,M.ThirdActiveMonth) AS SecondCalendarMonthGap
FROM CTE_SecondMonth M
WHERE M.FirstMonthOrderCount < M.SecondMonthOrderCount
AND M.ThirdMonthOrderCount < M.SecondMonthOrderCount
AND M.SecondActiveMonth IS NOT NULL
AND M.ThirdActiveMonth IS NOT NULL
ORDER BY
    M.CustomerID ASC,
    M.ThirdActiveMonth ASC;