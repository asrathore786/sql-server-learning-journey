/*

## **SQL Practice — Task 46**

Task 46

SQL Server 2022

Data Engineering

**Database:** `DataEngineeringPracticeDB_Lite`

**Suggested filename:** `task-046-customer-order-status-reconciliation.sql`

**Save folder:** `06_Data_Engineering/`

### **1. Business scenario**

An e-commerce company receives order information from two systems:

- **Order Management System (OMS):** Stores the current order status.
- **Payment System:** Stores payment transactions associated with each order.

The Finance and Data Engineering teams have discovered that some orders are marked as completed even though their payments are incomplete. Other orders have received more money than expected.

Your responsibility is to produce a reconciliation report identifying orders with inconsistent financial or operational statuses.

### **2. Business requirements**

Each order has an `OrderAmount`, `OrderStatus`, and potentially multiple payment transactions.

Payment transactions have three possible statuses: `SUCCESS`, `FAILED`, and `PENDING`.

Apply these rules:

1. Only `SUCCESS` payments contribute to the total amount received.
2. `FAILED` and `PENDING` payments must not contribute to the total.
3. Orders with no successful payments must have `TotalPaid = 0`.
4. An order is `OVERPAID` if successful payments exceed its order amount.
5. An order is `COMPLETED_UNDERPAID` if its status is `COMPLETED` but successful payments are less than its order amount.
6. An order is `CANCELLED_WITH_PAYMENT` if its status is `CANCELLED` and successful payments are greater than zero.
7. An order is `NOT_COMPLETED_BUT_FULLY_PAID` if its status is `PENDING` and successful payments equal its order amount.
8. Otherwise, the order is `VALID`.
9. Apply the reconciliation rules in the priority order shown above. For example, an overpaid cancelled order must be classified as `OVERPAID`.
10. Return **only orders classified as something other than&#x20;**`VALID`.

### **3. Dataset — Execute in SSMS**

```

USE DataEngineeringPracticeDB_Lite;
GO

DROP TABLE IF EXISTS #OrderPayments;
DROP TABLE IF EXISTS #CustomerOrders;

CREATE TABLE #CustomerOrders (
    OrderID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATE NOT NULL,
    OrderAmount DECIMAL(12,2) NOT NULL,
    OrderStatus VARCHAR(20) NOT NULL
);

CREATE TABLE #OrderPayments (
    PaymentID INT PRIMARY KEY,
    OrderID INT NOT NULL,
    PaymentDate DATETIME2(0) NOT NULL,
    PaymentAmount DECIMAL(12,2) NOT NULL,
    PaymentStatus VARCHAR(20) NOT NULL
);

INSERT INTO #CustomerOrders VALUES
(1001,201,'2026-11-01',5000,'COMPLETED'),
(1002,202,'2026-11-01',3000,'COMPLETED'),
(1003,203,'2026-11-02',4000,'PENDING'),
(1004,204,'2026-11-02',2500,'CANCELLED'),
(1005,205,'2026-11-03',6000,'COMPLETED'),
(1006,206,'2026-11-03',3500,'PENDING'),
(1007,207,'2026-11-04',2000,'CANCELLED'),
(1008,208,'2026-11-04',4500,'COMPLETED'),
(1009,209,'2026-11-05',5000,'PENDING'),
(1010,210,'2026-11-05',3000,'COMPLETED'),
(1011,211,'2026-11-06',2500,'CANCELLED'),
(1012,212,'2026-11-06',7000,'PENDING');

INSERT INTO #OrderPayments VALUES
(1,1001,'2026-11-01 10:00:00',5000,'SUCCESS'),

(2,1002,'2026-11-01 11:00:00',1000,'SUCCESS'),
(3,1002,'2026-11-01 12:00:00',500,'FAILED'),

(4,1003,'2026-11-02 09:00:00',4000,'SUCCESS'),

(5,1004,'2026-11-02 10:00:00',1000,'SUCCESS'),

(6,1005,'2026-11-03 09:00:00',4000,'SUCCESS'),
(7,1005,'2026-11-03 10:00:00',3000,'SUCCESS'),

(8,1006,'2026-11-03 11:00:00',1500,'SUCCESS'),
(9,1006,'2026-11-03 12:00:00',2000,'PENDING'),

(10,1007,'2026-11-04 10:00:00',2000,'FAILED'),

(11,1008,'2026-11-04 11:00:00',2000,'SUCCESS'),
(12,1008,'2026-11-04 12:00:00',2500,'SUCCESS'),

(13,1009,'2026-11-05 09:00:00',6000,'SUCCESS'),

(14,1010,'2026-11-05 10:00:00',1000,'FAILED'),
(15,1010,'2026-11-05 11:00:00',1000,'PENDING'),

(16,1011,'2026-11-06 09:00:00',1000,'SUCCESS'),
(17,1011,'2026-11-06 10:00:00',2000,'SUCCESS'),

(18,1012,'2026-11-06 11:00:00',3000,'SUCCESS'),
(19,1012,'2026-11-06 12:00:00',4000,'SUCCESS');

```

### **4. Required output**

Return the following columns in this exact order:

`OrderID`, `CustomerID`, `OrderStatus`, `OrderAmount`, `TotalPaid`, `PaymentDifference`, `ReconciliationStatus`

Where:

\\[ \text{PaymentDifference}=\text{TotalPaid}-\text{OrderAmount} \\]

A negative difference means the customer has paid less than the order amount. A positive difference means the order has received excess payment.

### **5. Expected output**

Exactly 7 exception records, sorted by OrderID ascending.

| OrderID | CustomerID | OrderStatus | OrderAmount | TotalPaid | PaymentDifference | ReconciliationStatus         |
| ------- | ---------- | ----------- | ----------- | --------- | ----------------- | ---------------------------- |
| 1002    | 202        | COMPLETED   | 3000.00     | 1000.00   | -2000.00          | COMPLETED_UNDERPAID          |
| 1003    | 203        | PENDING     | 4000.00     | 4000.00   | 0.00              | NOT_COMPLETED_BUT_FULLY_PAID |
| 1004    | 204        | CANCELLED   | 2500.00     | 1000.00   | -1500.00          | CANCELLED_WITH_PAYMENT       |
| 1005    | 205        | COMPLETED   | 6000.00     | 7000.00   | 1000.00           | OVERPAID                     |
| 1009    | 209        | PENDING     | 5000.00     | 6000.00   | 1000.00           | OVERPAID                     |
| 1010    | 210        | COMPLETED   | 3000.00     | 0.00      | -3000.00          | COMPLETED_UNDERPAID          |
| 1011    | 211        | CANCELLED   | 2500.00     | 3000.00   | 500.00            | OVERPAID                     |

### **6. Acceptance criteria**

Your query must:

- Return exactly 7 exception records.
- Include orders with no successful payments when they violate a reconciliation rule.
- Prevent payment duplication caused by incorrect join cardinality.
- Correctly aggregate multiple successful payments.
- Respect the specified classification priority.
- Return correct monetary values and negative differences.
- Exclude all `VALID` orders.
- Sort the final result by `OrderID` ascending.

### **7. Submission and assessment**

Submit your SQL query and, if possible, the SSMS output.

I will assess your solution out of 10, focusing on business-rule interpretation, aggregation grain, join cardinality, `NULL` handling, classification priority, and validation.

**No hints or solution before your first attempt.** After validation, I will provide correction points, a learning log, and Git commands.

I will wait for your attempt rather than automatically assigning another task.

*/

--`OrderID`, `CustomerID`, `OrderStatus`, `OrderAmount`, `TotalPaid`, `PaymentDifference`, `ReconciliationStatus`

WITH PaymentAmountValue AS
(
SELECT 
    C.OrderID,
    C.CustomerID AS CustomerID,
    P.OrderStatus AS OrderStatus,
    P.OrderAmount AS OrderAmount,
    P.PaymentAmount AS PaymentAmount,
    COALESCE(SUM(CASE 
        WHEN P.PaymentStatus = 'SUCCESS'
        THEN P.PaymentAmount 
    ELSE 0
    END),0) AS TotalPaid
FROM #CustomerOrders C
LEFT JOIN #OrderPayments P
ON C.OrderID = P.OrderID
GROUP BY 
    C.OrderID
    C.CustomerID,
    P.OrderStatus,
    P.OrderAmount,
    P.PaymentAmount

),
ReconcileFinal AS
(
SELECT
    P.OrderID,
    P.CustomerID,
    P.OrderStatus,
    P.OrderAmount,
    P.TotalPaid,
    P.TotalPaid - P.OrderAmount AS PaymentDifference,
    CASE
        WHEN
            P.TotalPaid - P.OrderAmount > 0 THEN 'OVERPAID'
        WHEN
            P.OrderStatus = 'COMPLETED' AND P.TotalPaid < P.OrderAmount THEN 'COMPLETED_UNDERPAID'
        WHEN
            P.OrderStatus = 'CANCELLED' AND P.TotalPaid > 0 THEN 'CANCELLED_WITH_PAYMENT'
        WHEN 
            P.OrderStatus = 'PENDING' AND P.TotalPaid = P.OrderAmount THEN 'NOT_COMPLETED_BUT_FULLY_PAID'
        ELSE 'VALID'
    END AS ReconciliationStatus
FROM PaymentAmount P
)

SELECT 
    OrderID,
    CustomerID,
    OrderStatus,
    OrderAmount,
    TotalPaid,
    PaymentDifference,
    ReconciliationStatus
FROM ReconcileFinal
WHERE ReconciliationStatus <> 'VALID'
ORDER BY OrderID ASC