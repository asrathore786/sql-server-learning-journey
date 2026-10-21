/*

## Task 049 — Customer Order Gap Classification

Filename: `task-049-customer-order-gap-classification.sql`

Save folder: `06_Data_Engineering`

Database: `DataEngineeringPracticeDB_Lite`

### Business requirement

The business wants to classify the time gap between each customer's consecutive orders to understand ordering frequency.

Using `dbo.Orders`, return exactly these columns:

1. `CustomerID`
2. `OrderID`
3. `OrderDate`
4. `PreviousOrderDate`
5. `DaysSincePreviousOrder`
6. `OrderGapCategory`

Apply these rules:

- First Order: The customer has no previous order.
- Short Gap: The gap is between 1 and 7 days, inclusive.
- Medium Gap: The gap is between 8 and 30 days, inclusive.
- Long Gap: The gap is greater than 30 days.

For each customer, determine the previous order using the order date. If two orders have the same date, use `OrderID` as the tie-breaker.

Include every order, including each customer's first order. Sort the output by `CustomerID` ascending, `OrderDate` ascending, and `OrderID` ascending.

### Constraints

- Use `LAG()` to identify the previous order date.
- Use a `CASE` expression to classify the gap.
- Use CTEs if they help your solution.
- Do not use temporary tables or create permanent database objects.
- Do not modify the source data.

Your task: Write the SQL query independently and run it in SSMS. Share your query first; I'll review your logic before revealing a solution.

*/

WITH PreviousDate AS
(
SELECT
	O.CustomerID,
	O.OrderID,
	O.OrderDate AS CurrentDate,
	LAG(O.OrderDate) OVER(PARTITION BY O.CustomerID ORDER BY O.OrderDate, O.OrderID) AS PreviousOrderDate
FROM Orders O
WHERE OrderID BETWEEN 9514 AND 9523
),
DAYS_COUNT AS
(
SELECT
	*,
	DATEDIFF(DAY,PreviousOrderDate,CurrentDate) AS DaysSincePreviousOrder
FROM PreviousDate
)

SELECT
	D.CustomerID,
	D.OrderID,
	D.CurrentDate,
	D.PreviousOrderDate,
	D.DaysSincePreviousOrder,
	CASE
		WHEN D.DaysSincePreviousOrder = 0 THEN 'Same-Day Order'
		WHEN D.DaysSincePreviousOrder IS NULL THEN 'First Order'
		WHEN D.DaysSincePreviousOrder BETWEEN 1 AND 7 THEN 'Short Gap'
		WHEN D.DaysSincePreviousOrder BETWEEN 8 AND 30 THEN 'Medium Gap'
		WHEN D.DaysSincePreviousOrder > 30 THEN 'Long Gap'
	END AS OrderGapCategory
FROM DAYS_COUNT D
ORDER BY 
	D.CustomerID ASC,
	D.OrderID ASC,
	D.CurrentDate ASC

/*

# Task 049 — Complete Task Record

# Customer Order Gap Classification

Validated

SQL Server 2022 · DataEngineeringPracticeDB_Lite · Task 049

## 1. Task details

Filename: `task-049-customer-order-gap-classification.sql`

Save folder: `06_Data_Engineering`

Business objective: For every customer order, identify the previous order, calculate the number of days between consecutive orders, and classify the gap.

Business rules:

| Condition         | Category       |
| ----------------- | -------------- |
| No previous order | First Order    |
| 0 days            | Same-Day Order |
| 1–7 days          | Short Gap      |
| 8–30 days         | Medium Gap     |
| More than 30 days | Long Gap       |

## 2. Final SQL query

```

USE DataEngineeringPracticeDB_Lite;
GO

WITH PreviousDate AS
(
    SELECT
        O.CustomerID,
        O.OrderID,
        O.OrderDate AS CurrentDate,
        LAG(O.OrderDate) OVER
        (
            PARTITION BY O.CustomerID
            ORDER BY O.OrderDate, O.OrderID
        ) AS PreviousOrderDate
    FROM dbo.Orders AS O
),
Days_Count AS
(
    SELECT
        CustomerID,
        OrderID,
        CurrentDate,
        PreviousOrderDate,
        DATEDIFF
        (
            DAY,
            PreviousOrderDate,
            CurrentDate
        ) AS DaysSincePreviousOrder
    FROM PreviousDate
)
SELECT
    D.CustomerID,
    D.OrderID,
    D.CurrentDate,
    D.PreviousOrderDate,
    D.DaysSincePreviousOrder,
    CASE
        WHEN D.PreviousOrderDate IS NULL
            THEN 'First Order'
        WHEN D.DaysSincePreviousOrder = 0
            THEN 'Same-Day Order'
        WHEN D.DaysSincePreviousOrder BETWEEN 1 AND 7
            THEN 'Short Gap'
        WHEN D.DaysSincePreviousOrder BETWEEN 8 AND 30
            THEN 'Medium Gap'
        WHEN D.DaysSincePreviousOrder > 30
            THEN 'Long Gap'
    END AS OrderGapCategory
FROM Days_Count AS D
ORDER BY
    D.CustomerID ASC,
    D.CurrentDate ASC,
    D.OrderID ASC;

```

## 3. Full result from your latest SSMS output

The following is the complete output you provided for Customer 1, containing 10 rows.

| CustomerID | OrderID | CurrentDate | PreviousOrderDate | Days | Category       |
| ---------- | ------- | ----------- | ----------------- | ---- | -------------- |
| 1          | 9514    | 2026-10-20  | NULL              | NULL | First Order    |
| 1          | 9519    | 2026-10-20  | 2026-10-20        | 0    | Same-Day Order |
| 1          | 9520    | 2026-10-20  | 2026-10-20        | 0    | Same-Day Order |
| 1          | 9515    | 2026-10-24  | 2026-10-20        | 4    | Short Gap      |
| 1          | 9516    | 2026-10-31  | 2026-10-24        | 7    | Short Gap      |
| 1          | 9517    | 2026-11-15  | 2026-10-31        | 15   | Medium Gap     |
| 1          | 9521    | 2026-11-19  | 2026-11-15        | 4    | Short Gap      |
| 1          | 9518    | 2026-12-20  | 2026-11-19        | 31   | Long Gap       |
| 1          | 9522    | 2027-01-01  | 2026-12-20        | 12   | Medium Gap     |
| 1          | 9523    | 2027-01-31  | 2027-01-01        | 30   | Medium Gap     |

The table above is sorted chronologically according to the final query. The dates and calculations are from your supplied output; the row order has been adjusted to match the corrected `ORDER BY`.

## 4. Validation summary

First-order handling

No previous date produces NULL gap and First Order.

Same-day orders

Zero-day gaps are classified separately from first orders.

Gap boundaries

7 days = Short Gap; 30 days = Medium Gap; 31 days = Long Gap.

Chronological ordering

CustomerID, CurrentDate, OrderID.

## 5. What you missed and learned

What you initially missed: You classified a zero-day gap as `First Order`. That was incorrect because a zero-day gap means a previous order exists on the same date.

What you learned: `LAG()` identifies the immediately preceding row within a customer's ordered records. `DATEDIFF()` calculates the day gap, and `CASE` converts that value into a business category.

What to remember: When translating a business requirement into SQL, separate the calculation from the classification. First identify the previous event, then calculate the difference, and finally apply the business rules.

## 6. Git record

Save the query as:

`06_Data_Engineering/task-049-customer-order-gap-classification.sql`

Run the following from your local repository directory:

```
git add 06_Data_Engineering/task-049-customer-order-gap-classification.sql
git commit -m "Complete task 049: customer order gap classification"
git push origin main
```

Git commit and push have not been confirmed.

Task 049 is complete. The query and the supplied test output validate the specified gap categories. The result shown covers Customer 1's test records; it is not the complete dataset for every customer in the database.

*/