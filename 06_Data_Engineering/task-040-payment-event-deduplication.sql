/*

## SQL Task 40 — Detect Duplicate Payment Events in an Ingestion Pipeline

Intermediate–Advanced

SQL Server 2022 · Data Engineering · Payment Processing

File: `06_Data_Engineering/task-040-payment-event-deduplication.sql`\
Database: `DataEngineeringPracticeDB_Lite`\
Practice table: `#PaymentEventIngestion`

### 1. Business requirement

A bank receives payment events from an external payment processing system.

Due to network retries, the same event may be delivered multiple times. Each delivery receives a different `IngestionID`, even though it represents the same business event.

The Data Engineering team must prepare a clean dataset for downstream payment processing.

Your responsibility is to retain exactly one record per unique payment event while identifying which ingestion records should be excluded as duplicates.

The business event is uniquely identified by:

`PaymentID + EventType + EventTimestamp`

When multiple ingestion records have the same business event key, retain the record with the smallest `IngestionID`.

### 2. Dataset setup

Execute this independent script in SSMS.

```
USE DataEngineeringPracticeDB_Lite;
GO

DROP TABLE IF EXISTS #PaymentEventIngestion;

CREATE TABLE #PaymentEventIngestion
(
    IngestionID INT PRIMARY KEY,
    PaymentID INT NOT NULL,
    EventType VARCHAR(20) NOT NULL,
    EventTimestamp DATETIME2(0) NOT NULL,
    ReceivedAt DATETIME2(0) NOT NULL
);

INSERT INTO #PaymentEventIngestion
(
    IngestionID,
    PaymentID,
    EventType,
    EventTimestamp,
    ReceivedAt
)
VALUES
(101, 5001, 'Initiated', '2026-10-25 09:00:00', '2026-10-25 09:00:02'),
(102, 5001, 'Initiated', '2026-10-25 09:00:00', '2026-10-25 09:00:08'),
(103, 5001, 'Success',   '2026-10-25 09:05:00', '2026-10-25 09:05:03'),
(104, 5002, 'Initiated', '2026-10-25 10:00:00', '2026-10-25 10:00:01'),
(105, 5002, 'Failed',    '2026-10-25 10:03:00', '2026-10-25 10:03:02'),
(106, 5002, 'Failed',    '2026-10-25 10:03:00', '2026-10-25 10:03:10'),
(107, 5003, 'Initiated', '2026-10-25 11:00:00', '2026-10-25 11:00:01'),
(108, 5003, 'Initiated', '2026-10-25 11:00:00', '2026-10-25 11:00:05'),
(109, 5003, 'Initiated', '2026-10-25 11:00:00', '2026-10-25 11:00:12'),
(110, 5003, 'Success',   '2026-10-25 11:10:00', '2026-10-25 11:10:02'),
(111, 5004, 'Initiated', '2026-10-25 12:00:00', '2026-10-25 12:00:01'),
(112, 5004, 'Success',   '2026-10-25 12:05:00', '2026-10-25 12:05:02'),
(113, 5004, 'Success',   '2026-10-25 12:05:00', '2026-10-25 12:05:09'),
(114, 5005, 'Initiated', '2026-10-25 13:00:00', '2026-10-25 13:00:01'),
(115, 5005, 'Failed',    '2026-10-25 13:08:00', '2026-10-25 13:08:02'),
(116, 5005, 'Failed',    '2026-10-25 13:08:00', '2026-10-25 13:08:15');
```

### 3. Your assignment

Write a read-only SQL query that produces a deduplicated payment-event dataset.

| # | Acceptance criterion                                                              |
| - | --------------------------------------------------------------------------------- |
| 1 | Identify unique events using all three business-key columns                       |
| 2 | Retain only the smallest `IngestionID` for each unique event                      |
| 3 | Return exactly one record per unique event                                        |
| 4 | Include all payment event types                                                   |
| 5 | Return the original `EventTimestamp` and `ReceivedAt`                             |
| 6 | Do not delete or update source records                                            |
| 7 | Sort the final output by `PaymentID ASC`, `EventTimestamp ASC`, `IngestionID ASC` |

### 4. Required output columns

| Column         | Description                           |
| -------------- | ------------------------------------- |
| IngestionID    | Retained ingestion record identifier  |
| PaymentID      | Payment identifier                    |
| EventType      | Event classification                  |
| EventTimestamp | Original business event timestamp     |
| ReceivedAt     | Time the retained record was received |

### 5. Evaluation

I will assess your query for correct business-key grain, deterministic record retention, output completeness, and SQL Server compatibility.

The expected output values are withheld until you submit your query.

Your turn: Execute the dataset setup and submit your SQL query with the SSMS result. I will review your logic first, then provide the expected result and score.

I will not assign Task 41 until you explicitly request it.

*/

--SELECT * FROM #PaymentEventIngestion


WITH DeduplicatedEvents AS
(
SELECT 
    IngestionID,
    PaymentID,
    EventType,
    EventTimestamp,
    ReceivedAt,
    ROW_NUMBER() OVER(PARTITION BY PaymentID,EventType,EventTimestamp ORDER BY IngestionID ASC) AS RN
FROM #PaymentEventIngestion
)
SELECT 
    IngestionID,
    PaymentID,
    EventType,
    EventTimestamp,
    ReceivedAt
FROM DeduplicatedEvents
WHERE RN = 1
ORDER BY
    PaymentID ASC,
    EventTimestamp ASC,
    IngestionID ASC

/*

## Task 40 — Final SQL Review ✅

Final score

# 10/10

Status

Completed & verified

Your SQL query is fully correct. You identified the correct business key, applied deterministic deduplication, and retained the ingestion record with the smallest `IngestionID` for each unique payment event.

Your submitted output also matches the expected dataset exactly.

### 1. Technical assessment

| Evaluation criterion              | Result     |
| --------------------------------- | ---------- |
| Correct CTE structure             | &#x20;Pass |
| Correct three-column business key | &#x20;Pass |
| `ROW_NUMBER()` implementation     | &#x20;Pass |
| `IngestionID ASC` retention rule  | &#x20;Pass |
| `WHERE RN = 1`                    | &#x20;Pass |
| All event types included          | &#x20;Pass |
| All five output columns           | &#x20;Pass |
| Correct final sorting             | &#x20;Pass |
| Source records unchanged          | &#x20;Pass |

### 2. Result verification

Source records

# 16

Retained records

# 10

Duplicate records excluded

# 6

All 10 returned records match the expected retained ingestion IDs.

| PaymentID | Retained IngestionIDs | Records retained |
| --------- | --------------------- | ---------------- |
| 5001      | 101, 103              | 2                |
| 5002      | 104, 105              | 2                |
| 5003      | 107, 110              | 2                |
| 5004      | 111, 112              | 2                |
| 5005      | 114, 115              | 2                |

### 3. Code review

Your most important expression is:

```
ROW_NUMBER() OVER (
    PARTITION BY PaymentID, EventType, EventTimestamp
    ORDER BY IngestionID ASC
) AS RN
```

This is correct because:

- `PARTITION BY` defines the unique business-event grain.
- `ORDER BY IngestionID ASC` places the earliest ingestion identifier first.
- `ROW_NUMBER()` assigns a unique sequence within each event group.
- `WHERE RN = 1` retains exactly one record per event.

Because `IngestionID` is the primary key, the ordering is deterministic.

You also correctly avoided partitioning by `ReceivedAt`, which would have prevented duplicate retries with different receipt times from being grouped together.

### 4. Correction points / learning log

| Area                         | Assessment |
| ---------------------------- | ---------- |
| Business-key identification  | Correct    |
| Window-function partitioning | Correct    |
| Deduplication                | Correct    |
| Deterministic row selection  | Correct    |
| Output completeness          | Correct    |
| Recurring mistake            | None       |

Production consideration: This approach works well for selecting deduplicated records in a query. For large streaming pipelines, you would also need to consider deduplication across ingestion batches, late-arriving events, and persistent state management.

No functional corrections are required.

### 5. Git checkpoint

File: `06_Data_Engineering/task-040-payment-event-deduplication.sql`\
Database: `DataEngineeringPracticeDB_Lite`

Save your verified SQL and execute:

```
git add 06_Data_Engineering/task-040-payment-event-deduplication.sql
git commit -m "Complete Task 40 payment event deduplication"
git push
```

Task 40 is officially closed — 10/10.

I will wait for your explicit instruction before assigning Task 41.

*/



SELECT 
    P1.IngestionID,
    P1.PaymentID,
    P1.EventType,
    P1.EventTimestamp,
    P1.ReceivedAt
FROM 
#PaymentEventIngestion P1
WHERE P1.IngestionID = 
(
SELECT
    MIN(P2.IngestionID) AS IngestionID
FROM #PaymentEventIngestion P2
WHERE 
P1.PaymentID = P2.PaymentID
AND P1.EventType = P2.EventType
AND P1.EventTimestamp = P2.EventTimeStamp
)
ORDER BY 
    P1.paymentID ASC,
    P1.EventTimestamp ASC,
    P1.IngestionID ASC
 
/*

## Task 40 — Correlated Subquery: Final Verification ✅

Final score

# 10/10

Status

Completed & verified

Your submitted SSMS output matches all 10 expected records, including `EventTimestamp` and `ReceivedAt`.

### 1. Result verification

| Validation                 | Expected  | Actual      | Result |
| -------------------------- | --------- | ----------- | ------ |
| Source records             | 16        | 16 in setup | Pass   |
| Retained records           | 10        | 10          | Pass   |
| Duplicate records excluded | 6         | 6           | Pass   |
| Incorrect retained IDs     | 0         | 0           | Pass   |
| Output ordering            | Ascending | Ascending   | Pass   |

### 2. Learning record

You have now solved the same business requirement using two different techniques.

| Technique                        | Score | Status    |
| -------------------------------- | ----- | --------- |
| `ROW_NUMBER()` with CTE          | 10/10 | Completed |
| Correlated subquery with `MIN()` | 10/10 | Completed |

Your main improvement: You successfully translated a window-function solution into a correlated subquery.

Your earlier error was comparing `EventType` with `PaymentID`, which caused SQL Server Error 245. You identified and corrected that issue.

One minor optimization remains: the inner `GROUP BY` is redundant because the correlation already limits the aggregate to the matching business event.

### 3. Git checkpoint

File: `06_Data_Engineering/task-040-payment-event-deduplication.sql`

Save both working approaches in the same SQL file, with separate comments identifying each approach.

```
git add 06_Data_Engineering/task-040-payment-event-deduplication.sql
git commit -m "Complete Task 40 deduplication using window function and correlated subquery"
git push
```

Task 40 is officially closed, including the additional subquery exercise.

I will wait for your instruction before assigning Task 41.

*/