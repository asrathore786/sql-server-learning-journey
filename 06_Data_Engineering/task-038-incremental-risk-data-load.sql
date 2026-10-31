/*

## SQL Task 38 — Incremental Customer Risk Data Load

Intermediate–Advanced

SQL Server 2022 · ETL · Incremental Loading · Data Engineering

File: `06_Data_Engineering/task-038-incremental-risk-data-load.sql`\
Database: `DataEngineeringPracticeDB_Lite`

### 1. Business requirement

A bank receives customer risk assessment records from its AML system throughout the day.

The Data Engineering team maintains two tables:

- Source: `#RiskAssessmentSource` — all records received from the AML system.
- Target: `#RiskAssessmentTarget` — records already processed by the data pipeline.

Your responsibility is to implement an incremental data load.

The pipeline must load only records that have not previously been inserted into the target.

The pipeline may be executed multiple times. It must not create duplicate records.

### 2. Dataset setup

Execute this standalone script in SSMS.

```
USE DataEngineeringPracticeDB_Lite;
GO

DROP TABLE IF EXISTS #RiskAssessmentTarget;
DROP TABLE IF EXISTS #RiskAssessmentSource;

CREATE TABLE #RiskAssessmentSource
(
    AssessmentID INT PRIMARY KEY,
    CustomerID VARCHAR(10) NOT NULL,
    RiskCategory VARCHAR(10) NOT NULL,
    AssessmentDate DATETIME2(0) NOT NULL
);

CREATE TABLE #RiskAssessmentTarget
(
    AssessmentID INT PRIMARY KEY,
    CustomerID VARCHAR(10) NOT NULL,
    RiskCategory VARCHAR(10) NOT NULL,
    AssessmentDate DATETIME2(0) NOT NULL
);

INSERT INTO #RiskAssessmentSource
(
    AssessmentID,
    CustomerID,
    RiskCategory,
    AssessmentDate
)
VALUES
(101, 'C101', 'Low',    '2026-10-20 09:00:00'),
(102, 'C102', 'High',   '2026-10-20 09:10:00'),
(103, 'C103', 'Medium', '2026-10-20 09:20:00'),
(104, 'C101', 'Medium', '2026-10-20 09:30:00'),
(105, 'C104', 'Low',    '2026-10-20 09:40:00'),
(106, 'C105', 'High',   '2026-10-20 09:50:00'),
(107, 'C102', 'Medium', '2026-10-20 10:00:00'),
(108, 'C106', 'Low',    '2026-10-20 10:10:00'),
(109, 'C107', 'High',   '2026-10-20 10:20:00'),
(110, 'C108', 'Medium', '2026-10-20 10:30:00');

-- Records already loaded by a previous pipeline execution
INSERT INTO #RiskAssessmentTarget
(
    AssessmentID,
    CustomerID,
    RiskCategory,
    AssessmentDate
)
VALUES
(101, 'C101', 'Low',    '2026-10-20 09:00:00'),
(102, 'C102', 'High',   '2026-10-20 09:10:00'),
(103, 'C103', 'Medium', '2026-10-20 09:20:00'),
(104, 'C101', 'Medium', '2026-10-20 09:30:00');
```

### 3. Your assignment

Write a SQL Server script that satisfies the following requirements:

| # | Acceptance criterion                                               |
| - | ------------------------------------------------------------------ |
| 1 | Identify source records not already present in the target          |
| 2 | Use `AssessmentID` as the unique record identifier                 |
| 3 | Insert only missing records into the target                        |
| 4 | Preserve all four source columns                                   |
| 5 | Do not modify existing target records                              |
| 6 | Running the load a second time must insert zero additional records |
| 7 | Return the complete target dataset sorted by `AssessmentID ASC`    |

### 4. Required output structure

After executing your incremental load, display:

| AssessmentID | CustomerID | RiskCategory | AssessmentDate |
| ------------ | ---------- | ------------ | -------------- |
| ...          | ...        | ...          | ...            |

Also report the number of records inserted during the first execution and the second execution.

The expected results are withheld until your submission.

### 5. Evaluation criteria

Your solution will be evaluated on incremental-load correctness, idempotency, duplicate prevention, target integrity, and SQL Server compatibility.

Important: This is a data-loading task, not a read-only query. You must insert records into the target table, but you must not delete or update existing records.

Your turn: Execute the setup, write your incremental-loading SQL, run it twice, and share your query and SSMS results.

I will review your implementation, score it out of 10, and provide the expected results after your attempt. I will not assign Task 39 until you explicitly request it.

*/

SELECT * FROM #RiskAssessmentTarget

INSERT INTO #RiskAssessmentTarget
    (
    AssessmentID,
    CustomerID,
    RiskCategory,
    AssessmentDate
)
SELECT 
    AssessmentID,
    CustomerID,
    RiskCategory,
    AssessmentDate
FROM #RiskAssessmentSource S
WHERE NOT EXISTS (SELECT 1 FROM #RiskAssessmentTarget T WHERE S.AssessmentID = T.AssessmentID)
ORDER BY 
    AssessmentID ASC

    /*

    ## Task 38 — Final SQL Review ✅

Final score

# 10/10

Status

Completed & verified

Your SSMS screenshots confirm that the incremental loading logic works correctly.

### 1. Execution verification

| Validation              | Expected | Actual | Result |
| ----------------------- | -------- | ------ | ------ |
| Initial target records  | 4        | 4      | Pass   |
| New records inserted    | 6        | 6      | Pass   |
| Repeat execution        | 0        | 0      | Pass   |
| Final target records    | 10       | 10     | Pass   |
| Duplicate AssessmentIDs | 0        | 0      | Pass   |

Your final result contains all 10 assessment records, with IDs 101–110, matching the expected dataset.

### 2. Technical assessment

| Requirement                           | Result     |
| ------------------------------------- | ---------- |
| `INSERT INTO ... SELECT`              | &#x20;Pass |
| Correct `NOT EXISTS` condition        | &#x20;Pass |
| Correct business key (`AssessmentID`) | &#x20;Pass |
| Existing records preserved            | &#x20;Pass |
| Incremental load                      | &#x20;Pass |
| Idempotency                           | &#x20;Pass |
| Final output completeness             | &#x20;Pass |

### 3. Correction points / learning log

Concept demonstrated: Idempotent incremental data loading.

You correctly implemented a source-to-target comparison that inserts missing records without reprocessing existing ones.

Two production considerations:

- `ORDER BY` is unnecessary in the `INSERT ... SELECT` statement. Use it in the final reporting query.
- For concurrent production pipelines, `NOT EXISTS` alone does not eliminate race conditions. The target primary key and appropriate transaction isolation help protect data integrity.

No functional corrections are required for this exercise.

### 4. Git checkpoint

File: `06_Data_Engineering/task-038-incremental-risk-data-load.sql`\
Database: `DataEngineeringPracticeDB_Lite`

Save your completed SQL script, then execute:

```
git add 06_Data_Engineering/task-038-incremental-risk-data-load.sql
git commit -m "Complete Task 38 idempotent incremental risk assessment load"
git push
```

Task 38 is officially closed — 10/10.

I will wait for your explicit instruction before assigning Task 39.

*/
