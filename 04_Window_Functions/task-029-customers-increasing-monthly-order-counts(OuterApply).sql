WITH CTE_MonthlyOrder AS
(
    SELECT
        C.CustomerID,
        C.CustomerName,
        DATEFROMPARTS(
            YEAR(O.OrderDate),
            MONTH(O.OrderDate),
            1
        ) AS CurrentMonth,
        COUNT(O.OrderID) AS CurrentMonthOrderCount
    FROM Customers C
    INNER JOIN Orders O
        ON O.CustomerID = C.CustomerID
    GROUP BY
        C.CustomerID,
        C.CustomerName,
        DATEFROMPARTS(
            YEAR(O.OrderDate),
            MONTH(O.OrderDate),
            1
        )
)
SELECT
    M.CustomerID,
    M.CustomerName,
    P.PreviousMonth,
    M.CurrentMonth,
    P.PreviousMonthOrderCount,
    M.CurrentMonthOrderCount,
    M.CurrentMonthOrderCount
        - P.PreviousMonthOrderCount AS OrderCountIncrease
FROM CTE_MonthlyOrder M
OUTER APPLY
(
    SELECT
        Previous.CurrentMonth AS PreviousMonth,
        Previous.CurrentMonthOrderCount AS PreviousMonthOrderCount
    FROM CTE_MonthlyOrder Previous
    WHERE Previous.CustomerID = M.CustomerID
      AND Previous.CurrentMonth = DATEADD(
          MONTH, -1, M.CurrentMonth
      )
) P
WHERE P.PreviousMonth IS NOT NULL
  AND M.CurrentMonthOrderCount > P.PreviousMonthOrderCount
ORDER BY
    M.CustomerID ASC,
    P.PreviousMonth ASC;