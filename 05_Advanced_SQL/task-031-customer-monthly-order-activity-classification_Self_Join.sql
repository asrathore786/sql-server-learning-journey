
WITH CTE_CURRENT_MONTH AS
(
    SELECT
        C.CustomerID,
        C.CustomerName,
        DATETRUNC(MONTH, O.OrderDate) AS CurrentMonth,
        COUNT(O.OrderID) AS CurrentMonthOrderCount,
        DENSE_RANK() OVER
        (
            PARTITION BY C.CustomerID
            ORDER BY DATETRUNC(MONTH, O.OrderDate)
        ) AS MonthRank
    FROM Customers C
    INNER JOIN Orders O
        ON O.CustomerID = C.CustomerID
    GROUP BY
        C.CustomerID,
        C.CustomerName,
        DATETRUNC(MONTH, O.OrderDate)
),
PREVIOUS_MONTH AS
(
    SELECT
        CurrentMonth.CustomerID,
        CurrentMonth.CustomerName,
        PreviousMonth.CurrentMonth AS PreviousMonth,
        CurrentMonth.CurrentMonth,
        PreviousMonth.CurrentMonthOrderCount AS PreviousMonthOrderCount,
        CurrentMonth.CurrentMonthOrderCount,
        DATEDIFF
        (
            MONTH,
            PreviousMonth.CurrentMonth,
            CurrentMonth.CurrentMonth
        ) AS CalendarMonthGap
    FROM CTE_CURRENT_MONTH CurrentMonth
    LEFT JOIN CTE_CURRENT_MONTH PreviousMonth
        ON CurrentMonth.CustomerID = PreviousMonth.CustomerID
        AND CurrentMonth.MonthRank = PreviousMonth.MonthRank + 1
)
SELECT
    CustomerID,
    CustomerName,
    PreviousMonth AS PreviousActiveMonth,
    CurrentMonth AS CurrentActiveMonth,
    PreviousMonthOrderCount,
    CurrentMonthOrderCount,
    CurrentMonthOrderCount - PreviousMonthOrderCount AS OrderCountChange,
    CalendarMonthGap,
    CASE
        WHEN PreviousMonth IS NULL THEN 'New Activity'
        WHEN CurrentMonthOrderCount > PreviousMonthOrderCount THEN 'Increased'
        WHEN CurrentMonthOrderCount < PreviousMonthOrderCount THEN 'Decreased'
        ELSE 'Unchanged'
    END AS ActivityClassification
FROM PREVIOUS_MONTH
ORDER BY
    CustomerID ASC,
    CurrentMonth ASC;
