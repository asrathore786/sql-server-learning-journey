/*

## Task 048 — Customer Order Sessionization

Filename: `task-048-customer-order-sessionization.sql` Save folder: `06_Data_Engineering` Database: `DataEngineeringPracticeDB_Lite` Table: `dbo.Orders`

### Business requirement

An e-commerce business wants to identify separate purchasing sessions for each customer based on order activity.

Treat each customer's orders as chronological events. If the gap between an order and the customer's immediately preceding order is more than 30 days, a new session begins. A gap of exactly 30 days remains part of the existing session.

Write a SQL query that assigns every order to a session and returns exactly these columns:

| Column                   | Requirement                                                                      |
| ------------------------ | -------------------------------------------------------------------------------- |
| `CustomerID`             | Customer who placed the order                                                    |
| `OrderID`                | Unique order identifier                                                          |
| `OrderDate`              | Order date                                                                       |
| `TotalAmount`            | Order amount                                                                     |
| `PreviousOrderDate`      | Date of the customer's immediately preceding order; `NULL` for their first order |
| `DaysSincePreviousOrder` | Number of days since the preceding order; `NULL` for their first order           |
| `NewSessionFlag`         | `1` if this order starts a new session, otherwise `0`                            |
| `SessionNumber`          | Sequential session number for each customer, starting at `1`                     |

### Rules and constraints

- Use `LAG()` to identify the preceding order.
- A customer's first order starts Session 1 and has `NewSessionFlag = 1`.
- A gap greater than 30 days starts a new session.
- A gap of 30 days or less continues the current session.
- Session numbers must restart for each customer.
- Include every order, including customers with only one order.
- Sort by `CustomerID ASC`, `OrderDate ASC`, `OrderID ASC`.
- Use read-only SQL. CTEs and window functions are allowed.
- Do not use temporary tables or create database objects.

Expected outcome: each order is assigned to the correct session according to the 30-day inactivity rule.

Submit your SQL attempt first. I’ll review your logic without revealing the solution, and you can run the revised query in SSMS and share output for 1–2 customers.

*/

WITH Monthly_Revenue AS
(
SELECT 
	O.customerID,
	O.orderID,
	O.OrderDate AS ActivityMonth,
	O.TotalAmount
FROM Orders O
WHERE O.CustomerID = 1
),

PreviousDetails AS
(
SELECT
	M.customerID,
	M.OrderID,
	M.ActivityMonth,
	M.TotalAmount,
	LAG(M.ActivityMonth) OVER(PARTITION BY M.CustomerID ORDER BY M.ActivityMonth, M.orderID) AS PreviousMonth
FROM Monthly_Revenue M
),
DaysCount AS
(
SELECT 
	P.CustomerID,
	P.OrderID,
	P.ActivityMonth,
	P.TotalAmount,
	P.PreviousMonth,
	DATEDIFF(DAY,P.PreviousMonth,P.ActivityMonth) AS DayDifference,
		CASE 
		WHEN DATEDIFF(DAY,P.PreviousMonth,P.ActivityMonth) IS NULL OR DATEDIFF(DAY,P.PreviousMonth,P.ActivityMonth) > 30 THEN 1
		ELSE 0
		END AS NewSessionFlag
FROM PreviousDetails P
)

SELECT
	D.CustomerID,
	D.OrderID,
	D.ActivityMonth AS OrderDate,
	D.TotalAmount,
	D.PreviousMonth AS PreviousOrderDate,
	D.DayDifference AS DaysSincePreviousOrder,
	D.NewSessionFlag,
	SUM(NewSessionFlag) OVER(PARTITION BY D.CustomerID ORDER BY D.ActivityMonth,D.OrderID ROWS UNBOUNDED PRECEDING) AS SessionNumber
FROM DaysCount D
ORDER BY 
	D.CustomerID ASC,
	D.ActivityMonth ASC,
	D.OrderID ASC

/*

# Task 048 — Customer Order Sessionization

Status:&#x20;

Completed and validated for Customer 1



Filename: `task-048-customer-order-sessionization.sql`

Folder: `06_Data_Engineering`

## 1. Business requirement

Identify customer order sessions using the time gap between consecutive orders.

- A new session starts when the customer places their first order.
- A new session starts when the gap between consecutive orders is greater than 30 days.
- A gap of exactly 30 days stays in the same session.
- Each customer's session numbering starts at 1.
- Use `LAG()` to retrieve the previous order date.
- Use a cumulative window function to calculate the session number.

## 2. Final validated SQL query

```

USE DataEngineeringPracticeDB_Lite;
GO

WITH OrderDetails AS
(
    SELECT
        O.CustomerID,
        O.OrderID,
        O.OrderDate,
        O.TotalAmount
    FROM dbo.Orders AS O
),
PreviousDetails AS
(
    SELECT
        O.CustomerID,
        O.OrderID,
        O.OrderDate,
        O.TotalAmount,
        LAG(O.OrderDate) OVER
        (
            PARTITION BY O.CustomerID
            ORDER BY O.OrderDate, O.OrderID
        ) AS PreviousOrderDate
    FROM OrderDetails AS O
),
DaysCount AS
(
    SELECT
        P.CustomerID,
        P.OrderID,
        P.OrderDate,
        P.TotalAmount,
        P.PreviousOrderDate,
        DATEDIFF
        (
            DAY,
            P.PreviousOrderDate,
            P.OrderDate
        ) AS DaysSincePreviousOrder,
        CASE
            WHEN P.PreviousOrderDate IS NULL THEN 1
            WHEN DATEDIFF
                 (
                     DAY,
                     P.PreviousOrderDate,
                     P.OrderDate
                 ) > 30 THEN 1
            ELSE 0
        END AS NewSessionFlag
    FROM PreviousDetails AS P
)
SELECT
    D.CustomerID,
    D.OrderID,
    D.OrderDate,
    D.TotalAmount,
    D.PreviousOrderDate,
    D.DaysSincePreviousOrder,
    D.NewSessionFlag,
    SUM(D.NewSessionFlag) OVER
    (
        PARTITION BY D.CustomerID
        ORDER BY D.OrderDate, D.OrderID
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS SessionNumber
FROM DaysCount AS D
ORDER BY
    D.CustomerID ASC,
    D.OrderDate ASC,
    D.OrderID ASC;

```

## 3. Output validation

You shared the SSMS output for Customer 1. The observed results were consistent with the sessionization rules.

| Scenario                                       | Observed result                                     |
| ---------------------------------------------- | --------------------------------------------------- |
| First order                                    | `NewSessionFlag = 1`, session starts at 1           |
| Gap greater than 30 days                       | Starts a new session                                |
| Orders on the same date                        | Remain in the same session                          |
| Orders 9511, 9512 and 9513 on October 20, 2026 | All belong to session 21; only order 9511 starts it |

The complete output for all customers was not independently reviewed in the conversation. Also, the exact 30-day boundary was not present in the sample you shared, although the query's `> 30` condition implements that rule correctly.

## 4. What you learned

- `LAG()` retrieves the previous order date within each customer.
- `DATEDIFF(DAY, PreviousOrderDate, OrderDate)` calculates the date difference in days.
- `CASE` identifies whether an order starts a new session.
- Cumulative `SUM()` converts the session-start flags into sequential session numbers.
- `PARTITION BY CustomerID` keeps customers' session numbering independent.
- `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` explicitly defines the cumulative window frame.

The reusable pattern is:

`Previous event → Calculate gap → Identify boundary → Cumulative sum → Group/session number`

## 5. Git record

Save the query at:

`06_Data_Engineering/task-048-customer-order-sessionization.sql`

Then run these commands from your repository directory:

```
git add 06_Data_Engineering/task-048-customer-order-sessionization.sql
git commit -m "Complete task 048: customer order sessionization"
git push origin main
```

These commands are provided for your record; commit and push completion has not been confirmed.
*/