/*

## **SQL Practice — Task 47**

Task 47

SQL Server 2022

Data Engineering

**Database:** `DataEngineeringPracticeDB_Lite`

**Suggested filename:** `task-047-customer-order-lifecycle-validation.sql`

**Save folder:** `06_Data_Engineering/`

### **1. Business scenario**

An e-commerce company stores every change to an order's status in an event-history table.

The Operations team suspects that some orders have passed through invalid status transitions, while others have remained incomplete for too long.

Your responsibility is to examine the complete event history of each order and identify **invalid status transitions**.

The company has defined the following permitted transitions:

Permitted paths: CREATED → CONFIRMED, CREATED → CANCELLED, CONFIRMED → SHIPPED, CONFIRMED → CANCELLED, SHIPPED → DELIVERED.

### **2. Business requirements**

1. Examine status events independently for each `OrderID`.
2. Process events in ascending `EventDateTime` order.
3. When timestamps are identical, use `EventID` ascending as the tie-breaker.
4. Compare each event's `OrderStatus` with the immediately preceding status for the same order.
5. The first event for every order must have status `CREATED`.
6. Only the five transitions shown in the diagram are permitted.
7. Repeated statuses are invalid (for example, `CONFIRMED → CONFIRMED`).
8. `DELIVERED` and `CANCELLED` are terminal statuses; no further status changes are permitted.
9. Report each invalid event separately, even if an order has multiple invalid events.
10. Return only invalid events.

**Important:** Evaluate each transition against the actual previous event, even when that previous event was itself invalid. Do not repair or skip events while evaluating the sequence.

### **3. Dataset — Execute in SSMS**

```

USE DataEngineeringPracticeDB_Lite;
GO

DROP TABLE IF EXISTS #OrderStatusEvents;

CREATE TABLE #OrderStatusEvents (
    EventID INT PRIMARY KEY,
    OrderID INT NOT NULL,
    EventDateTime DATETIME2(0) NOT NULL,
    OrderStatus VARCHAR(20) NOT NULL
);

INSERT INTO #OrderStatusEvents VALUES
-- Order 1001: valid lifecycle
(101,1001,'2026-11-01 09:00:00','CREATED'),
(102,1001,'2026-11-01 10:00:00','CONFIRMED'),
(103,1001,'2026-11-02 12:00:00','SHIPPED'),
(104,1001,'2026-11-04 14:00:00','DELIVERED'),

-- Order 1002: skips confirmation
(201,1002,'2026-11-01 09:00:00','CREATED'),
(202,1002,'2026-11-01 11:00:00','SHIPPED'),
(203,1002,'2026-11-03 15:00:00','DELIVERED'),

-- Order 1003: repeated status
(301,1003,'2026-11-02 08:00:00','CREATED'),
(302,1003,'2026-11-02 09:00:00','CONFIRMED'),
(303,1003,'2026-11-02 10:00:00','CONFIRMED'),
(304,1003,'2026-11-03 12:00:00','SHIPPED'),

-- Order 1004: cancellation followed by activity
(401,1004,'2026-11-02 08:00:00','CREATED'),
(402,1004,'2026-11-02 09:00:00','CANCELLED'),
(403,1004,'2026-11-02 10:00:00','CONFIRMED'),

-- Order 1005: invalid initial status
(501,1005,'2026-11-03 09:00:00','CONFIRMED'),
(502,1005,'2026-11-04 09:00:00','SHIPPED'),

-- Order 1006: valid cancellation
(601,1006,'2026-11-03 10:00:00','CREATED'),
(602,1006,'2026-11-03 11:00:00','CONFIRMED'),
(603,1006,'2026-11-03 12:00:00','CANCELLED'),

-- Order 1007: invalid backward transition
(701,1007,'2026-11-04 08:00:00','CREATED'),
(702,1007,'2026-11-04 09:00:00','CONFIRMED'),
(703,1007,'2026-11-05 10:00:00','SHIPPED'),
(704,1007,'2026-11-05 11:00:00','CONFIRMED'),

-- Order 1008: identical timestamps
(801,1008,'2026-11-04 08:00:00','CREATED'),
(802,1008,'2026-11-04 09:00:00','CONFIRMED'),
(803,1008,'2026-11-04 09:00:00','SHIPPED'),
(804,1008,'2026-11-04 09:00:00','DELIVERED'),

-- Order 1009: multiple invalid events
(901,1009,'2026-11-05 08:00:00','CREATED'),
(902,1009,'2026-11-05 09:00:00','DELIVERED'),
(903,1009,'2026-11-05 10:00:00','SHIPPED'),
(904,1009,'2026-11-05 11:00:00','DELIVERED'),

-- Order 1010: valid but unfinished
(1001,1010,'2026-11-06 08:00:00','CREATED'),
(1002,1010,'2026-11-06 09:00:00','CONFIRMED'),

-- Order 1011: repeated initial status
(1101,1011,'2026-11-06 08:00:00','CREATED'),
(1102,1011,'2026-11-06 09:00:00','CREATED'),

-- Order 1012: valid direct cancellation
(1201,1012,'2026-11-06 10:00:00','CREATED'),
(1202,1012,'2026-11-06 11:00:00','CANCELLED');

```

### **4. Required output**

Return these columns in exactly this order:

`OrderID`, `EventID`, `EventDateTime`, `PreviousStatus`, `CurrentStatus`, `ValidationStatus`

For every invalid event, `ValidationStatus` must contain one of these values:

| Condition                       | ValidationStatus         |
| ------------------------------- | ------------------------ |
| First event is not CREATED      | `INVALID_INITIAL_STATUS` |
| Any other prohibited transition | `INVALID_TRANSITION`     |

For the first event of an order, `PreviousStatus` must be `NULL`.

### **5. Expected output**

Exactly 8 invalid events, ordered by OrderID, EventDateTime, EventID.

| OrderID | EventID | PreviousStatus | CurrentStatus | ValidationStatus       |
| ------- | ------- | -------------- | ------------- | ---------------------- |
| 1002    | 202     | CREATED        | SHIPPED       | INVALID_TRANSITION     |
| 1003    | 303     | CONFIRMED      | CONFIRMED     | INVALID_TRANSITION     |
| 1004    | 403     | CANCELLED      | CONFIRMED     | INVALID_TRANSITION     |
| 1005    | 501     | NULL           | CONFIRMED     | INVALID_INITIAL_STATUS |
| 1007    | 704     | SHIPPED        | CONFIRMED     | INVALID_TRANSITION     |
| 1009    | 902     | CREATED        | DELIVERED     | INVALID_TRANSITION     |
| 1009    | 903     | DELIVERED      | SHIPPED       | INVALID_TRANSITION     |
| 1011    | 1102    | CREATED        | CREATED       | INVALID_TRANSITION     |

The table above omits `EventDateTime` for readability; your SQL output must include it.

### **6. Acceptance criteria**

Your solution must:

- Identify all 8 invalid events.
- Preserve event-level granularity.
- Correctly handle the first event of each order.
- Use `EventID` to resolve identical timestamps.
- Detect repeated statuses and transitions after terminal statuses.
- Evaluate actual consecutive events, without skipping invalid history.
- Exclude valid events, including the unfinished but otherwise valid OrderID `1010`.
- Return the specified six columns in the correct order.

### **7. Submission instructions**

Submit your SQL query and SSMS result.

I will assess it out of 10 based on event sequencing, transition validation, NULL handling, business-rule interpretation, and result accuracy.

**No hints or solution before your first attempt.** After validation, I will provide your correction points, learning log, and Git commands.

*/

SELECT
    EventID,
    OrderID,
    EventDateTime,
    OrderStatus,
    DENSE_RANK() OVER(PARTITION BY OrderID ORDER BY EventDateTime ASC, EventID ASC) AS RNK
FROM #OrderStatusEvents