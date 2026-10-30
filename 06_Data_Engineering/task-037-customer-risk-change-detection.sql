/*
## SQL Task 37 — Detect Changes in Customer Risk Classification

Intermediate–Advanced

SQL Server 2022 · Window Functions · Banking Risk · CDC

File: `06_Data_Engineering/task-037-customer-risk-change-detection.sql`\
Database: `DataEngineeringPracticeDB_Lite`\
Practice table: `#CustomerRiskHistory`

### 1. Business requirement

A bank maintains historical customer risk classifications for AML and compliance monitoring.

Customers can move between three risk categories: `Low`, `Medium`, and `High`.

The Compliance Data Engineering team needs to identify every actual change in a customer's risk classification so those changes can be sent to a downstream monitoring system.

For example, a customer moving from `Low` to `High` represents a change. A repeated `High` classification does not.

### 2. Dataset setup

Execute this independent dataset in SSMS:

```
USE DataEngineeringPracticeDB_Lite;
GO

DROP TABLE IF EXISTS #CustomerRiskHistory;

CREATE TABLE #CustomerRiskHistory
(
    RiskHistoryID INT PRIMARY KEY,
    CustomerID VARCHAR(10) NOT NULL,
    RiskCategory VARCHAR(10) NOT NULL,
    AssessmentDate DATETIME2(0) NOT NULL
);

INSERT INTO #CustomerRiskHistory
(
    RiskHistoryID,
    CustomerID,
    RiskCategory,
    AssessmentDate
)
VALUES
(1,  'C101', 'Low',    '2026-10-01 09:00:00'),
(2,  'C101', 'Medium', '2026-10-05 10:00:00'),
(3,  'C101', 'Medium', '2026-10-08 11:00:00'),
(4,  'C101', 'High',   '2026-10-12 12:00:00'),

(5,  'C102', 'High',   '2026-10-01 09:30:00'),
(6,  'C102', 'High',   '2026-10-07 10:30:00'),
(7,  'C102', 'Medium', '2026-10-15 14:00:00'),

(8,  'C103', 'Low',    '2026-10-02 08:00:00'),

(9,  'C104', 'Medium', '2026-10-03 09:00:00'),
(10, 'C104', 'Low',    '2026-10-06 10:00:00'),
(11, 'C104', 'High',   '2026-10-10 15:00:00'),

(12, 'C105', 'Low',    '2026-10-01 08:00:00'),
(13, 'C105', 'Medium', '2026-10-09 13:00:00'),
(14, 'C105', 'Low',    '2026-10-20 16:00:00'),

(15, 'C106', 'High',   '2026-10-11 09:00:00'),
(16, 'C106', 'Medium', '2026-10-11 09:00:00');
```

Keep the same SSMS connection open because the dataset uses a local temporary table.

### 3. Your assignment

Write a read-only SQL query that identifies every genuine risk classification change.

| # | Acceptance criterion                                                                   |
| - | -------------------------------------------------------------------------------------- |
| 1 | Compare each customer's current assessment with their immediately preceding assessment |
| 2 | Evaluate customers independently                                                       |
| 3 | Use `AssessmentDate ASC` to determine chronological order                              |
| 4 | Use `RiskHistoryID ASC` to resolve identical timestamps                                |
| 5 | Exclude the first assessment of each customer                                          |
| 6 | Exclude repeated assessments where the risk category did not change                    |
| 7 | Include both risk upgrades and downgrades                                              |
| 8 | Sort by `CustomerID ASC`, then `AssessmentDate ASC`, then `RiskHistoryID ASC`          |

### 4. Required output structure

| Column               | Description                         |
| -------------------- | ----------------------------------- |
| CustomerID           | Customer identifier                 |
| PreviousRiskCategory | Risk category before the change     |
| CurrentRiskCategory  | New risk category                   |
| AssessmentDate       | Date and time of the new assessment |
| RiskHistoryID        | Identifier of the new assessment    |

The expected result values are withheld until you submit your query.

### 5. Evaluation

Your SQL will be assessed on correct chronological comparison, customer-level partitioning, handling of repeated classifications, deterministic tie-breaking, output completeness, and SQL Server compatibility.

Your turn: Write the query independently and submit your SQL. I'll review it, assign a score out of 10, and share the expected output after your attempt.

I will not assign Task 38 until you explicitly request it.

*/

WITH GetPreviousCategory AS
(
SELECT 
    RiskHistoryID,
    CustomerID,
    RiskCategory ,
    LAG(RiskCategory) OVER(PARTITION BY CustomerID ORDER BY AssessmentDate ASC, RiskHistoryID ASC) AS PreviousRiskCategory,
    AssessmentDate
FROM #CustomerRiskHistory
)

SELECT
    customerID,
    PreviousRiskCategory,
    RiskCategory AS CurrentRiskCategory,
    AssessmentDate,
    RiskHistoryID
FROM GetPreviousCategory
WHERE PreviousRiskCategory <> RiskCategory
ORDER BY 
    CustomerID ASC,
    AssessmentDate ASC,
    RiskHistoryID ASC


/*

## Task 37 — Final SQL Review ✅

Final score

# 10/10

Status

Completed & verified

Your SQL is 100% correct against the supplied business requirements. All eight rows in your SSMS output match the expected results, including chronological comparisons, risk upgrades, downgrades, and identical-timestamp handling.

### 1. Technical assessment

| Evaluation criteria                    | Result     |
| -------------------------------------- | ---------- |
| Correct use of `LAG()`                 | &#x20;Pass |
| `PARTITION BY CustomerID`              | &#x20;Pass |
| `AssessmentDate ASC`                   | &#x20;Pass |
| `RiskHistoryID ASC` tie-breaker        | &#x20;Pass |
| Exclude first assessments              | &#x20;Pass |
| Exclude unchanged risk classifications | &#x20;Pass |
| Include upgrades and downgrades        | &#x20;Pass |
| Required output columns and sorting    | &#x20;Pass |

### 2. Result verification

Expected rows

8

Actual rows

8

Mismatched rows

0

### 3. Code review

Your central logic is correct:

```
LAG(RiskCategory) OVER (
    PARTITION BY CustomerID
    ORDER BY AssessmentDate ASC, RiskHistoryID ASC
) AS PreviousRiskCategory
```

This retrieves the immediately preceding risk classification for each customer.

Your filtering condition is also correct:

```
WHERE PreviousRiskCategory <> RiskCategory
```

Since the first assessment produces `NULL` from `LAG()`, the comparison evaluates to UNKNOWN and the row is excluded under SQL Server's standard NULL semantics.

Because `RiskCategory` is defined as `NOT NULL` in this exercise, the logic is reliable.

### 4. Correction points / learning log

| Topic                  | Assessment                   |
| ---------------------- | ---------------------------- |
| `LAG()`                | Correctly implemented        |
| Window partitioning    | Correct customer-level grain |
| Deterministic ordering | Correct                      |
| NULL handling          | Correct for supplied schema  |
| Risk-change detection  | Correct                      |
| Recurring mistake      | None in this task            |

Production consideration: If risk categories become nullable in a real banking dataset, `<>` alone will not detect transitions involving NULL. The comparison would need explicit NULL handling.

You have demonstrated correct use of `LAG()` for change detection, a technique used in CDC processing, SCD Type 2 workflows, and regulatory audit pipelines.

### 5. Git checkpoint

File: `06_Data_Engineering/task-037-customer-risk-change-detection.sql`\
Database: `DataEngineeringPracticeDB_Lite`

Save your verified SQL query, then execute:

```
git add 06_Data_Engineering/task-037-customer-risk-change-detection.sql
git commit -m "Complete Task 37 customer risk classification change detection"
git push
```

Task 37 is officially closed — 10/10.

I will wait until you explicitly request Task 38.

*/