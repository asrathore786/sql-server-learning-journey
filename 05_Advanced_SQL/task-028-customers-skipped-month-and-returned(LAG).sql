WITH CTE_MonthlyOrder AS
(
    SELECT
        O.CustomerID,
        DATEFROMPARTS(YEAR(O.OrderDate), MONTH(O.OrderDate), 1) AS ActiveMonth,
        COUNT(*) AS ActiveMonthOrderCount
    FROM Orders O
    GROUP BY
        O.CustomerID,
        DATEFROMPARTS(YEAR(O.OrderDate), MONTH(O.OrderDate), 1)
),
CTE_MonthGaps AS
(
    SELECT
        CustomerID,
        ActiveMonth,
        ActiveMonthOrderCount,
        LAG(ActiveMonth) OVER (
            PARTITION BY CustomerID
            ORDER BY ActiveMonth
        ) AS PreviousActiveMonth,
        LAG(ActiveMonthOrderCount) OVER (
            PARTITION BY CustomerID
            ORDER BY ActiveMonth
        ) AS PreviousActiveMonthOrderCount
    FROM CTE_MonthlyOrder
)
SELECT
    C.CustomerID,
    C.CustomerName,
    G.PreviousActiveMonth AS LastActiveMonth,
    DATEADD(MONTH, 1, G.PreviousActiveMonth) AS SkippedMonth,
    G.ActiveMonth AS ReturnMonth,
    G.PreviousActiveMonthOrderCount AS LastActiveOrderCount,
    G.ActiveMonthOrderCount AS ReturnOrderCount
FROM CTE_MonthGaps G
INNER JOIN Customers C
    ON C.CustomerID = G.CustomerID
WHERE DATEDIFF(MONTH, G.PreviousActiveMonth, G.ActiveMonth) = 2
ORDER BY
    C.CustomerID,
    G.PreviousActiveMonth;