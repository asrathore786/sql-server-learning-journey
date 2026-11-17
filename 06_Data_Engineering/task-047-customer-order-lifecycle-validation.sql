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

WITH OrderedEvents AS (
SELECT
    EventID,
    OrderID,
    EventDateTime,
    OrderStatus AS CurrentStatus,
    LAG(OrderStatus) OVER (PARTITION BY OrderID ORDER BY EventDateTime, EventID) AS PreviousStatus
FROM #OrderStatusEvents
),
InvalidTransitions AS (
    SELECT
        OrderID,
        EventID,
        EventDateTime,
        PreviousStatus,
        CurrentStatus,
        CASE 
            WHEN PreviousStatus IS NULL AND CurrentStatus <> 'CREATED' THEN 'INVALID_INITIAL_STATUS'
            WHEN PreviousStatus = 'CREATED' AND CurrentStatus NOT IN ('CONFIRMED', 'CANCELLED') THEN 'INVALID_TRANSITION'
            WHEN PreviousStatus = 'CONFIRMED' AND CurrentStatus NOT IN ('SHIPPED', 'CANCELLED') THEN 'INVALID_TRANSITION'
            WHEN PreviousStatus = 'SHIPPED' AND CurrentStatus <> 'DELIVERED' THEN 'INVALID_TRANSITION'
            WHEN PreviousStatus IN ('DELIVERED', 'CANCELLED') THEN 'INVALID_TRANSITION'
            WHEN PreviousStatus = CurrentStatus THEN 'INVALID_TRANSITION'
            ELSE NULL
        END AS ValidationStatus
    FROM OrderedEvents
)

SELECT  
    OrderID,
    EventID,
    EventDateTime,
    PreviousStatus,
    CurrentStatus,
    ValidationStatus
FROM 
    InvalidTransitions
WHERE 
    ValidationStatus IS NOT NULL
ORDER BY 
    OrderID, EventDateTime, EventID;

/*

## **Task 47 — SQL Review: Attempt 1**

Final score

# **10/10**

Status

Passed — First Attempt

Your SQL is correct, and your submitted SSMS output matches **all 8 expected invalid events**.

You successfully translated the order-lifecycle rules into event-level validation without losing the original sequence of events.

## **1. Technical assessment**

| Evaluation criterion                | Result |
| ----------------------------------- | ------ |
| Event ordering by date and EventID  | Pass   |
| Independent validation per OrderID  | Pass   |
| Previous status identification      | Pass   |
| Invalid initial status detection    | Pass   |
| Invalid forward transitions         | Pass   |
| Backward transitions                | Pass   |
| Repeated status detection           | Pass   |
| Terminal status enforcement         | Pass   |
| Correct output columns and ordering | Pass   |
| Actual SSMS output                  | Pass   |

## **2. Output verification**

Your result contains exactly the expected invalid events.

| OrderID | EventID | ValidationStatus       | Result |
| ------- | ------- | ---------------------- | ------ |
| 1002    | 202     | INVALID_TRANSITION     |        |
| 1003    | 303     | INVALID_TRANSITION     |        |
| 1004    | 403     | INVALID_TRANSITION     |        |
| 1005    | 501     | INVALID_INITIAL_STATUS |        |
| 1007    | 704     | INVALID_TRANSITION     |        |
| 1009    | 902     | INVALID_TRANSITION     |        |
| 1009    | 903     | INVALID_TRANSITION     |        |
| 1011    | 1102    | INVALID_TRANSITION     |        |

&#x20;8 expected records = 8 actual records. No missing or extra records.

## **3. Detailed SQL review**

### **A.&#x20;**`OrderedEvents`**&#x20;CTE**

Your use of:

```
LAG(OrderStatus) OVER (
    PARTITION BY OrderID
    ORDER BY EventDateTime, EventID
) AS PreviousStatus
```

is exactly appropriate.

It ensures that each event is compared against the immediately preceding event for the same order, even if the preceding event was invalid.

**One unnecessary expression:**

```
DENSE_RANK() OVER (
    PARTITION BY OrderID
    ORDER BY EventDateTime, EventID
) AS RNK
```

You calculate `RNK`, but never use it.

This is not a correctness error. However, it introduces an unnecessary window calculation.

You can remove it to simplify the query.

### **B.&#x20;**`InvalidTransitions`**&#x20;CTE**

Your `CASE` expression correctly implements the transition rules.

For example:

```
WHEN PreviousStatus = 'CREATED'
     AND CurrentStatus NOT IN ('CONFIRMED', 'CANCELLED')
THEN 'INVALID_TRANSITION'
```

This correctly identifies `CREATED → SHIPPED` as invalid.

You also correctly handled terminal statuses:

```
WHEN PreviousStatus IN ('DELIVERED', 'CANCELLED')
THEN 'INVALID_TRANSITION'
```

This prevents further transitions after an order has reached a terminal state.

**Minor observation:** Your condition `WHEN PreviousStatus = CurrentStatus` is redundant for the defined status vocabulary because the earlier transition checks already reject repeated statuses. It does not cause an error.

### **C. Final SELECT**

Your final filtering is correct:

```
WHERE ValidationStatus IS NOT NULL
```

This returns only invalid events while preserving the original event-level granularity.

The final ordering is also correct.

## **4. Correction points / learning log**

| Skill                               | Assessment        |
| ----------------------------------- | ----------------- |
| Business requirement interpretation | Excellent         |
| Event sequence processing           | Excellent         |
| `LAG()` implementation              | Correct           |
| `CASE` business rules               | Correct           |
| NULL handling                       | Correct           |
| Output grain                        | Correct           |
| SQL simplification                  | Minor improvement |
| Independent validation              | Correct           |

**Principle learned:** In event-history validation, the immediately preceding event is the reference point for evaluating the current event. Invalid events must not automatically be removed from the sequence because doing so would change subsequent comparisons.

One production consideration: your `PreviousStatus IS NULL` condition assumes stored statuses are non-NULL. The supplied dataset satisfies that assumption. In production, a nullable status column would require explicit handling to distinguish a missing previous event from a previous event whose status is NULL.

## **5. Git checkpoint**

**File:** `06_Data_Engineering/task-047-customer-order-lifecycle-validation.sql`

```
git add 06_Data_Engineering/task-047-customer-order-lifecycle-validation.sql
git commit -m "Complete Task 47 customer order lifecycle validation"
git push
```

## **Final assessment**

**Task 47: 10/10 — completed and verified on the first attempt.**

Your solution demonstrates strong control over event sequencing, window functions, and rule-based data validation.

The only suggested improvements are removing unused calculations and simplifying redundant conditions. Neither affects your score.

I will wait for your instruction before assigning Task 48.

*/

/*
Yes. For **Task 47 — Customer Order Lifecycle Validation**, your original solution used `LAG()` to identify the previous status.

We can solve the same problem using a **correlated subquery with&#x20;**`OUTER APPLY`, without using `LAG()`, `ROW_NUMBER()`, or `DENSE_RANK()`.

## **Alternative Method 1 — OUTER APPLY**

```
WITH OrderedEvents AS
(
    SELECT
        E.OrderID,
        E.EventID,
        E.EventDateTime,
        P.OrderStatus AS PreviousStatus,
        E.OrderStatus AS CurrentStatus
    FROM #OrderStatusEvents E

    OUTER APPLY
    (
        SELECT TOP (1)
            P.OrderStatus
        FROM #OrderStatusEvents P
        WHERE P.OrderID = E.OrderID
          AND (
                P.EventDateTime < E.EventDateTime
                OR (
                    P.EventDateTime = E.EventDateTime
                    AND P.EventID < E.EventID
                )
              )
        ORDER BY
            P.EventDateTime DESC,
            P.EventID DESC
    ) P
),
ValidationResults AS
(
    SELECT
        OrderID,
        EventID,
        EventDateTime,
        PreviousStatus,
        CurrentStatus,
        CASE
            WHEN PreviousStatus IS NULL
                 AND CurrentStatus <> 'CREATED'
                THEN 'INVALID_INITIAL_STATUS'

            WHEN PreviousStatus = 'CREATED'
                 AND CurrentStatus NOT IN ('CONFIRMED', 'CANCELLED')
                THEN 'INVALID_TRANSITION'

            WHEN PreviousStatus = 'CONFIRMED'
                 AND CurrentStatus NOT IN ('SHIPPED', 'CANCELLED')
                THEN 'INVALID_TRANSITION'

            WHEN PreviousStatus = 'SHIPPED'
                 AND CurrentStatus <> 'DELIVERED'
                THEN 'INVALID_TRANSITION'

            WHEN PreviousStatus IN ('DELIVERED', 'CANCELLED')
                THEN 'INVALID_TRANSITION'

            ELSE NULL
        END AS ValidationStatus
    FROM OrderedEvents
)
SELECT
    OrderID,
    EventID,
    EventDateTime,
    PreviousStatus,
    CurrentStatus,
    ValidationStatus
FROM ValidationResults
WHERE ValidationStatus IS NOT NULL
ORDER BY
    OrderID,
    EventDateTime,
    EventID;
```

### **How OUTER APPLY works**

Consider OrderID `1002`:

| EventID | CurrentStatus | PreviousStatus |
| ------- | ------------- | -------------- |
| 201     | CREATED       | NULL           |
| 202     | SHIPPED       | CREATED        |
| 203     | DELIVERED     | SHIPPED        |

For EventID `202`, the subquery searches for earlier events belonging to OrderID `1002`.

It sorts them in descending chronological order and selects `TOP (1)`, which gives the immediately preceding event.

`OUTER APPLY` preserves the first event even when no previous event exists.

This produces the same previous-status relationship as `LAG()`.

## **Alternative Method 2 — Self JOIN with NOT EXISTS**

Another approach uses a self-join and an anti-existence condition to identify the immediately preceding event.

```
WITH EventHistory AS
(
    SELECT
        E.OrderID,
        E.EventID,
        E.EventDateTime,
        P.OrderStatus AS PreviousStatus,
        E.OrderStatus AS CurrentStatus
    FROM #OrderStatusEvents E
    LEFT JOIN #OrderStatusEvents P
        ON E.OrderID = P.OrderID
       AND (
            P.EventDateTime < E.EventDateTime
            OR (
                P.EventDateTime = E.EventDateTime
                AND P.EventID < E.EventID
            )
       )
       AND NOT EXISTS
       (
           SELECT 1
           FROM #OrderStatusEvents X
           WHERE X.OrderID = E.OrderID
             AND (
                 X.EventDateTime > P.EventDateTime
                 OR (
                     X.EventDateTime = P.EventDateTime
                     AND X.EventID > P.EventID
                 )
             )
             AND (
                 X.EventDateTime < E.EventDateTime
                 OR (
                     X.EventDateTime = E.EventDateTime
                     AND X.EventID < E.EventID
                 )
             )
       )
),
ValidationResults AS
(
    SELECT
        OrderID,
        EventID,
        EventDateTime,
        PreviousStatus,
        CurrentStatus,
        CASE
            WHEN PreviousStatus IS NULL
                 AND CurrentStatus <> 'CREATED'
                THEN 'INVALID_INITIAL_STATUS'

            WHEN PreviousStatus = 'CREATED'
                 AND CurrentStatus NOT IN ('CONFIRMED', 'CANCELLED')
                THEN 'INVALID_TRANSITION'

            WHEN PreviousStatus = 'CONFIRMED'
                 AND CurrentStatus NOT IN ('SHIPPED', 'CANCELLED')
                THEN 'INVALID_TRANSITION'

            WHEN PreviousStatus = 'SHIPPED'
                 AND CurrentStatus <> 'DELIVERED'
                THEN 'INVALID_TRANSITION'

            WHEN PreviousStatus IN ('DELIVERED', 'CANCELLED')
                THEN 'INVALID_TRANSITION'

            ELSE NULL
        END AS ValidationStatus
    FROM EventHistory
)
SELECT
    OrderID,
    EventID,
    EventDateTime,
    PreviousStatus,
    CurrentStatus,
    ValidationStatus
FROM ValidationResults
WHERE ValidationStatus IS NOT NULL
ORDER BY OrderID, EventDateTime, EventID;
```

Here, `NOT EXISTS` ensures there is no event between the candidate previous event and the current event.

### **Comparison of all three approaches**

| Method        | Main technique            | Complexity | Practical use                                                    |
| ------------- | ------------------------- | ---------- | ---------------------------------------------------------------- |
| Your original | `LAG()`                   | Low        | Sequential event analysis                                        |
| Alternative 1 | `OUTER APPLY` + `TOP (1)` | Medium     | Finding the most recent related record                           |
| Alternative 2 | Self JOIN + `NOT EXISTS`  | High       | Understanding predecessor relationships without window functions |

All three should return the same **8 invalid events** for Task 47.

**My recommendation:** Keep your original `LAG()` solution as the primary implementation. It is simpler and communicates the requirement more directly. Learn `OUTER APPLY` as an alternative because it is useful for retrieving the latest related record in SQL Server.

For large datasets, compare actual execution plans and logical reads before deciding which approach performs best. An index on `(OrderID, EventDateTime, EventID)` with `OrderStatus` included can help predecessor lookups.

*/