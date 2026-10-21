/*

## Task 038 — Customer Payment Reliability Analysis

Intermediate–Advanced

Data Engineering

SQL Server 2022

Save folder: `06_Data_Engineering`

Filename: `task-038-customer-payment-reliability-analysis.sql`

Database: `DataEngineeringPracticeDB`

## Business requirement

The Finance and Risk teams want to identify customers whose orders have experienced payment problems. Build a customer-level payment reliability report using the existing `Customers`, `Orders`, and `Payments` tables.

For each customer who has placed at least one order, calculate:

- Total number of orders.
- Total order value.
- Number of orders with at least one payment record.
- Number of orders with at least one Failed payment.
- Number of orders with at least one Pending payment.
- Number of orders whose total recorded payment amount differs from the order amount.
- Payment reliability percentage, defined as:

\\[ \text{Payment Reliability \\%} = \frac{\text{Orders with no Failed or Pending payments and matching payment total}} {\text{Total Orders}} \times 100 \\]

Business rules:

1. Count each order only once per metric, even if it has multiple payment records.
2. An order with no payment record is not reliable.
3. An order with any Failed or Pending payment is not reliable.
4. An order is reliable only when it has at least one payment record, has no Failed or Pending payments, and the sum of all payment amounts equals the order amount.
5. Do not count customers who have never placed an order.
6. Round the reliability percentage to two decimal places.
7. Return all customers who have placed orders, including those with zero reliable orders.
8. Sort by reliability percentage ascending, then total order value descending.

## Expected output

Your query must return these columns in this order:

| Column                      | Description                                              |
| --------------------------- | -------------------------------------------------------- |
| `CustomerID`                | Customer identifier                                      |
| `CustomerName`              | Customer name                                            |
| `TotalOrders`               | Number of orders                                         |
| `TotalOrderValue`           | Sum of order amounts                                     |
| `OrdersWithPayments`        | Orders with at least one payment record                  |
| `OrdersWithFailedPayments`  | Orders with one or more Failed payments                  |
| `OrdersWithPendingPayments` | Orders with one or more Pending payments                 |
| `OrdersWithAmountMismatch`  | Orders whose payment total differs from the order amount |
| `ReliableOrders`            | Orders satisfying all reliability conditions             |
| `PaymentReliabilityPct`     | Reliable orders divided by total orders, as a percentage |

## Constraints

- Use CTEs to organize the logic.
- Avoid multiplying order amounts when an order has multiple payment records.
- Use SQL Server syntax.
- Handle division by zero defensively, even though customers without orders must be excluded.
- Do not use temporary tables or create new database objects.

I’m giving you the requirement only—no hints or solution before your attempt.

Submit your complete SQL query. I’ll review it first, identify any logic errors, and provide the full task record after it passes validation.

*/

WITH Payment_Summary AS
(
SELECT 
	O.CustomerID,
	O.OrderID,
	O.TotalAmount AS OrderAmount,
	COUNT(P.PaymentID) AS PaymentRecordCount,
	SUM(P.PaymentAmount) AS TotalPaymentAmount,
	SUM( CASE WHEN P.PaymentStatus = 'Failed' THEN 1 ELSE 0 END) AS HasFailedPayment,
	SUM( CASE WHEN P.PaymentStatus = 'Pending' THEN 1 ELSE 0 END) AS HasPendingPayment
FROM Orders O
LEFT JOIN Payments P
	ON O.OrderID = P.OrderID
GROUP BY O.CustomerID,
		O.OrderID,
		O.TotalAmount
)
,
CustomerPaymentSummary AS
(
SELECT 
	O.CustomerID,
	COUNT(*) AS TotalOrders,
	SUM(OrderAmount) AS TotalOrderValue,
	SUM(CASE WHEN PaymentRecordCount > 0 THEN 1 ELSE 0 END) AS OrdersWithPayments,
	SUM(CASE WHEN HasFailedPayment >= 1 THEN 1 ELSE 0 END) AS OrdersWithFailedPayments,
    SUM(CASE WHEN HasPendingPayment >= 1 THEN 1 ELSE 0 END) AS OrdersWithPendingPayments,	
	SUM(CASE WHEN COALESCE(TotalPaymentAmount, 0) <> OrderAmount THEN 1 ELSE 0 END) AS OrdersWithAmountMismatch,
	SUM(CASE
	        WHEN PaymentRecordCount > 0
	             AND HasFailedPayment = 0
	             AND HasPendingPayment = 0
	             AND TotalPaymentAmount = OrderAmount
	        THEN 1 ELSE 0
	    END) AS ReliableOrders
FROM Payment_Summary O
GROUP BY O.CustomerID
)

SELECT	
	C.CustomerID,
    C.CustomerName,
    CPS.TotalOrders,
    CPS.TotalOrderValue,
    CPS.OrdersWithPayments,
    CPS.OrdersWithFailedPayments,
    CPS.OrdersWithPendingPayments,
    CPS.OrdersWithAmountMismatch,
    CPS.ReliableOrders,
    CAST(100.0 * CPS.ReliableOrders / NULLIF(CPS.TotalOrders, 0) AS Decimal(10,2)) AS PaymentReliabilityPct
FROM CustomerPaymentSummary CPS
INNER JOIN Customers C
		ON C.CustomerID = CPS.CustomerID 
ORDER By PaymentReliabilityPct ASC,
		TotalOrderValue DESC




/*
Yes. For Task 038 — Customer Payment Reliability Analysis — there are at least three valid SQL approaches. Your current solution uses two CTEs and conditional aggregation. A second approach is to use `EXISTS` for payment-status checks, and a third is to use a single CTE with window functions or conditional aggregates.

I recommend learning the `EXISTS` approach next because it teaches you how to express business rules without multiplying order rows.

## Approach 1: Your current solution — Two CTEs

Technique: Aggregate payments at order level, then aggregate orders at customer level.

```
WITH Payment_Summary AS
(
    SELECT
        O.CustomerID,
        O.OrderID,
        O.TotalAmount AS OrderAmount,
        COUNT(P.PaymentID) AS PaymentRecordCount,
        COALESCE(SUM(P.PaymentAmount), 0) AS TotalPaymentAmount,
        SUM(CASE WHEN P.PaymentStatus = 'Failed'
                 THEN 1 ELSE 0 END) AS FailedCount,
        SUM(CASE WHEN P.PaymentStatus = 'Pending'
                 THEN 1 ELSE 0 END) AS PendingCount
    FROM dbo.Orders O
    LEFT JOIN dbo.Payments P
        ON P.OrderID = O.OrderID
    GROUP BY
        O.CustomerID,
        O.OrderID,
        O.TotalAmount
),
Customer_Summary AS
(
    SELECT
        CustomerID,
        COUNT(*) AS TotalOrders,
        SUM(OrderAmount) AS TotalOrderValue,
        SUM(CASE WHEN PaymentRecordCount > 0
                 THEN 1 ELSE 0 END) AS OrdersWithPayments,
        SUM(CASE WHEN FailedCount > 0
                 THEN 1 ELSE 0 END) AS OrdersWithFailedPayments,
        SUM(CASE WHEN PendingCount > 0
                 THEN 1 ELSE 0 END) AS OrdersWithPendingPayments,
        SUM(CASE WHEN TotalPaymentAmount <> OrderAmount
                 THEN 1 ELSE 0 END) AS OrdersWithAmountMismatch,
        SUM(CASE
                WHEN PaymentRecordCount > 0
                 AND FailedCount = 0
                 AND PendingCount = 0
                 AND TotalPaymentAmount = OrderAmount
                THEN 1 ELSE 0
            END) AS ReliableOrders
    FROM Payment_Summary
    GROUP BY CustomerID
)
SELECT
    C.CustomerID,
    C.CustomerName,
    S.TotalOrders,
    S.TotalOrderValue,
    S.OrdersWithPayments,
    S.OrdersWithFailedPayments,
    S.OrdersWithPendingPayments,
    S.OrdersWithAmountMismatch,
    S.ReliableOrders,
    CAST(100.0 * S.ReliableOrders /
         NULLIF(S.TotalOrders, 0) AS DECIMAL(10,2))
         AS PaymentReliabilityPct
FROM Customer_Summary S
INNER JOIN dbo.Customers C
    ON C.CustomerID = S.CustomerID
ORDER BY
    PaymentReliabilityPct ASC,
    TotalOrderValue DESC;
```

This is a good, readable solution. It makes the change in aggregation level explicit. Notice that `COUNT(P.PaymentID)` is preferable to `COUNT(P.OrderID)` here because `PaymentID` is the payment record's key.

## Approach 2: Use `EXISTS` for payment-status checks

Technique: Aggregate payment amounts per order, then use correlated `EXISTS` predicates to determine whether failed or pending payments exist.

This separates two different questions:

- How much has been paid?
- Does any payment have a particular status?

```
WITH Order_Summary AS
(
    SELECT
        O.CustomerID,
        O.OrderID,
        O.TotalAmount AS OrderAmount,
        COUNT(P.PaymentID) AS PaymentRecordCount,
        COALESCE(SUM(P.PaymentAmount), 0) AS TotalPaymentAmount,
        CASE WHEN EXISTS
        (
            SELECT 1
            FROM dbo.Payments P2
            WHERE P2.OrderID = O.OrderID
              AND P2.PaymentStatus = 'Failed'
        ) THEN 1 ELSE 0 END AS HasFailedPayment,
        CASE WHEN EXISTS
        (
            SELECT 1
            FROM dbo.Payments P3
            WHERE P3.OrderID = O.OrderID
              AND P3.PaymentStatus = 'Pending'
        ) THEN 1 ELSE 0 END AS HasPendingPayment
    FROM dbo.Orders O
    LEFT JOIN dbo.Payments P
        ON P.OrderID = O.OrderID
    GROUP BY
        O.CustomerID,
        O.OrderID,
        O.TotalAmount
),
Customer_Summary AS
(
    SELECT
        CustomerID,
        COUNT(*) AS TotalOrders,
        SUM(OrderAmount) AS TotalOrderValue,
        SUM(CASE WHEN PaymentRecordCount > 0
                 THEN 1 ELSE 0 END) AS OrdersWithPayments,
        SUM(HasFailedPayment) AS OrdersWithFailedPayments,
        SUM(HasPendingPayment) AS OrdersWithPendingPayments,
        SUM(CASE WHEN TotalPaymentAmount <> OrderAmount
                 THEN 1 ELSE 0 END) AS OrdersWithAmountMismatch,
        SUM(CASE
                WHEN PaymentRecordCount > 0
                 AND HasFailedPayment = 0
                 AND HasPendingPayment = 0
                 AND TotalPaymentAmount = OrderAmount
                THEN 1 ELSE 0
            END) AS ReliableOrders
    FROM Order_Summary
    GROUP BY CustomerID
)
SELECT
    C.CustomerID,
    C.CustomerName,
    S.TotalOrders,
    S.TotalOrderValue,
    S.OrdersWithPayments,
    S.OrdersWithFailedPayments,
    S.OrdersWithPendingPayments,
    S.OrdersWithAmountMismatch,
    S.ReliableOrders,
    CAST(100.0 * S.ReliableOrders /
         NULLIF(S.TotalOrders, 0) AS DECIMAL(10,2))
         AS PaymentReliabilityPct
FROM Customer_Summary S
INNER JOIN dbo.Customers C
    ON C.CustomerID = S.CustomerID
ORDER BY
    PaymentReliabilityPct ASC,
    TotalOrderValue DESC;
```

### Why this works

`EXISTS` returns a Boolean-style result: it checks whether at least one matching record exists. Even if an order has five failed payment records, `HasFailedPayment` is still `1`, so the customer-level metric counts that order only once.

This is often a natural way to express requirements such as “has at least one,” “has ever,” or “no matching record exists.”

## Approach 3: Pre-aggregate payments, then join to orders

Technique: Summarize the `Payments` table independently before joining it to `Orders`.

This is useful in data engineering because it makes the payment aggregation explicit and can simplify joins when several downstream metrics use the same payment summary.

The core pattern is:

```
WITH Payment_Aggregate AS
(
    SELECT
        OrderID,
        COUNT(*) AS PaymentRecordCount,
        SUM(PaymentAmount) AS TotalPaymentAmount,
        SUM(CASE WHEN PaymentStatus = 'Failed'
                 THEN 1 ELSE 0 END) AS FailedCount,
        SUM(CASE WHEN PaymentStatus = 'Pending'
                 THEN 1 ELSE 0 END) AS PendingCount
    FROM dbo.Payments
    GROUP BY OrderID
),
Order_Summary AS
(
    SELECT
        O.CustomerID,
        O.OrderID,
        O.TotalAmount AS OrderAmount,
        COALESCE(P.PaymentRecordCount, 0) AS PaymentRecordCount,
        COALESCE(P.TotalPaymentAmount, 0) AS TotalPaymentAmount,
        COALESCE(P.FailedCount, 0) AS FailedCount,
        COALESCE(P.PendingCount, 0) AS PendingCount
    FROM dbo.Orders O
    LEFT JOIN Payment_Aggregate P
        ON P.OrderID = O.OrderID
)
SELECT
    CustomerID,
    COUNT(*) AS TotalOrders,
    SUM(OrderAmount) AS TotalOrderValue,
    SUM(CASE WHEN PaymentRecordCount > 0
             THEN 1 ELSE 0 END) AS OrdersWithPayments,
    SUM(CASE WHEN FailedCount > 0
             THEN 1 ELSE 0 END) AS OrdersWithFailedPayments,
    SUM(CASE WHEN PendingCount > 0
             THEN 1 ELSE 0 END) AS OrdersWithPendingPayments,
    SUM(CASE WHEN TotalPaymentAmount <> OrderAmount
             THEN 1 ELSE 0 END) AS OrdersWithAmountMismatch,
    SUM(CASE
            WHEN PaymentRecordCount > 0
             AND FailedCount = 0
             AND PendingCount = 0
             AND TotalPaymentAmount = OrderAmount
            THEN 1 ELSE 0
        END) AS ReliableOrders
FROM Order_Summary
GROUP BY CustomerID;
```

This query produces the customer-level metrics but omits `CustomerName`, `PaymentReliabilityPct`, and the required final ordering. Those can be added to complete the original task. The key architectural difference is that the payment table is aggregated first, rather than grouping a direct `Orders`–`Payments` join.

## Which approach should you learn first?

| Approach        | Main concept             | Best use                                    |
| --------------- | ------------------------ | ------------------------------------------- |
| Two CTEs        | Multi-level aggregation  | Complex reporting requirements              |
| `EXISTS`        | Existence checks         | “At least one,” “any,” or “none” conditions |
| Pre-aggregation | Control join cardinality | Large datasets and reusable summaries       |

My recommendation: Master Approach 1 first, then practise Approach 2. Approach 3 is also valuable for data engineering, especially when you need to reason about one-to-many joins and aggregation before joining.

One caution: the three approaches are logically equivalent for the metrics shown only when the same business rules are applied consistently. Performance can differ depending on indexes, data distribution, and the SQL Server execution plan. Run them against the same dataset and compare results before comparing performance.
*/