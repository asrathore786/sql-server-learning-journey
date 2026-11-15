/*

## SQL Practice — Task 42

Task 42

SQL Server 2022

Data Engineering

File: `06_Data_Engineering/task-042-customer-daily-balance-validation.sql`

Database: `DataEngineeringPracticeDB_Lite`

### 1. Business requirement

A bank maintains daily closing balances for customer accounts. During the daily data pipeline, some balance records may be missing, while others may have been loaded more than once.

The Data Engineering team needs to identify accounts with incomplete or duplicate daily balance records during the reporting period.

Reporting period: 1 October 2026 to 5 October 2026, inclusive.

Your query must return one row per account that has at least one missing or duplicate balance date.

The output must include:

- `AccountID`
- `CustomerID`
- `ExpectedDays` — number of calendar days in the reporting period
- `ActualDays` — number of distinct dates with balance records
- `MissingDays` — expected days minus actual days
- `DuplicateRecords` — number of additional records beyond one per account per date
- `ValidationStatus` — `MISSING_DAYS`, `DUPLICATE_RECORDS`, or `MISSING_AND_DUPLICATE`

Accounts with complete daily coverage and no duplicates must be excluded.

### 2. Dataset — Execute in SSMS

```

USE DataEngineeringPracticeDB_Lite;
GO

DROP TABLE IF EXISTS #DailyAccountBalances;
DROP TABLE IF EXISTS #BankAccounts;

CREATE TABLE #BankAccounts (
    AccountID INT PRIMARY KEY,
    CustomerID INT NOT NULL
);

CREATE TABLE #DailyAccountBalances (
    BalanceRecordID INT PRIMARY KEY,
    AccountID INT NOT NULL,
    BalanceDate DATE NOT NULL,
    ClosingBalance DECIMAL(14,2) NOT NULL
);

INSERT INTO #BankAccounts VALUES
(1001, 201),
(1002, 202),
(1003, 203),
(1004, 204),
(1005, 205),
(1006, 206),
(1007, 207),
(1008, 208);

INSERT INTO #DailyAccountBalances VALUES
-- Account 1001: Complete
(1,1001,'2026-10-01',10000),
(2,1001,'2026-10-02',10500),
(3,1001,'2026-10-03',10200),
(4,1001,'2026-10-04',11000),
(5,1001,'2026-10-05',11500),

-- Account 1002: Missing Oct 3
(6,1002,'2026-10-01',20000),
(7,1002,'2026-10-02',20500),
(8,1002,'2026-10-04',21000),
(9,1002,'2026-10-05',21500),

-- Account 1003: Duplicate Oct 2
(10,1003,'2026-10-01',30000),
(11,1003,'2026-10-02',30500),
(12,1003,'2026-10-02',30500),
(13,1003,'2026-10-03',31000),
(14,1003,'2026-10-04',31500),
(15,1003,'2026-10-05',32000),

-- Account 1004: Missing Oct 2 and Oct 4
(16,1004,'2026-10-01',40000),
(17,1004,'2026-10-03',41000),
(18,1004,'2026-10-05',42000),

-- Account 1005: Missing and duplicate
(19,1005,'2026-10-01',50000),
(20,1005,'2026-10-02',50500),
(21,1005,'2026-10-02',50500),
(22,1005,'2026-10-04',51500),
(23,1005,'2026-10-05',52000),

-- Account 1006: Complete
(24,1006,'2026-10-01',60000),
(25,1006,'2026-10-02',60500),
(26,1006,'2026-10-03',61000),
(27,1006,'2026-10-04',61500),
(28,1006,'2026-10-05',62000),

-- Account 1007: Only one day
(29,1007,'2026-10-03',70000),

-- Account 1008: Duplicate Oct 1 and Oct 5
(30,1008,'2026-10-01',80000),
(31,1008,'2026-10-01',80000),
(32,1008,'2026-10-02',80500),
(33,1008,'2026-10-03',81000),
(34,1008,'2026-10-04',81500),
(35,1008,'2026-10-05',82000),
(36,1008,'2026-10-05',82000);

```

### 3. Expected output

Six rows, ordered by AccountID ascending.

| AccountID | CustomerID | ExpectedDays | ActualDays | MissingDays | DuplicateRecords | ValidationStatus      |
| --------- | ---------- | ------------ | ---------- | ----------- | ---------------- | --------------------- |
| 1002      | 202        | 5            | 4          | 1           | 0                | MISSING_DAYS          |
| 1003      | 203        | 5            | 5          | 0           | 1                | DUPLICATE_RECORDS     |
| 1004      | 204        | 5            | 3          | 2           | 0                | MISSING_DAYS          |
| 1005      | 205        | 5            | 4          | 1           | 1                | MISSING_AND_DUPLICATE |
| 1007      | 207        | 5            | 1          | 4           | 0                | MISSING_DAYS          |
| 1008      | 208        | 5            | 5          | 0           | 2                | DUPLICATE_RECORDS     |

### 4. Acceptance criteria

Your SQL must:

1. Evaluate all eight accounts, including those without balance records.
2. Count distinct balance dates within the reporting period.
3. Calculate additional duplicate records accurately.
4. Classify missing and duplicate conditions independently, including when both occur.
5. Exclude accounts with no validation issues.
6. Return exactly six rows in the specified order.

Important: Do not assume the number of balance records equals the number of distinct balance dates.

### 5. Submission

Execute the dataset in `DataEngineeringPracticeDB_Lite`, write your solution independently, and share your SQL query along with the actual SSMS result.

I will evaluate the business logic, aggregation, output grain, edge cases, and result accuracy out of 10. No hints or solution are provided at this stage.

*/

WITH DaysCount
AS
(
SELECT AccountID AS AccountID,
    DATEDIFF(Day,'2026-09-30','2026-10-05') AS ExpectedDays,
    COUNT(BALANCEDATE) AS WithDuplicate,
    COUNT(DISTINCT BALANCEDATE) AS ActualDays,
    DATEDIFF(DAY,MIN(BalanceDate),MAX(BalanceDate)) + 1 AS DateDiff
FROM #DailyAccountBalances
WHERE BalanceDate BETWEEN '2026-10-01' AND '2026-10-05'
GROUP BY
    AccountID
)

SELECT 
    D.AccountID,
    B.CustomerID,
    D.ExpectedDays,
    D.ActualDays AS ActualDays,
    D.ExpectedDays - D.ActualDays AS MissingDays,
    D.WithDuplicate - D.ActualDays  AS DuplicateRecords,
    CASE 
        WHEN
            D.WithDuplicate = D.ActualDays THEN 'MISSING_DAYS'
        WHEN
            D.ActualDays = D.ExpectedDays AND D.WithDuplicate > D.ExpectedDays THEN 'DUPLICATE_RECORDS'
        WHEN
            D.ExpectedDays = D.WithDuplicate AND D.ActualDays < D.ExpectedDays THEN 'MISSING_AND_DUPLICATE'
    END AS ValidationStatus
FROM DaysCount D
LEFT JOIN #BankAccounts B
    ON B.AccountID = D.AccountID
WHERE NOT (D.ActualDays = D.ExpectedDays AND D.WithDuplicate = D.ExpectedDays)
ORDER BY D.AccountID ASC ;


--| AccountID | CustomerID | ExpectedDays | ActualDays | MissingDays | DuplicateRecords | ValidationStatus      |
--| --------- | ---------- | ------------ | ---------- | ----------- | ---------------- | --------------------- |
--| 1002      | 202        | 5            | 4          | 1           | 0                | MISSING_DAYS          |
--| 1003      | 203        | 5            | 5          | 0           | 1                | DUPLICATE_RECORDS     |
--| 1004      | 204        | 5            | 3          | 2           | 0                | MISSING_DAYS          |
--| 1005      | 205        | 5            | 4          | 1           | 1                | MISSING_AND_DUPLICATE |
--| 1007      | 207        | 5            | 1          | 4           | 0                | MISSING_DAYS          |
--| 1008      | 208        | 5            | 5          | 0           | 2                | DUPLICATE_RECORDS     |



WITH ReportingPeriod AS (
    -- Step 1: Define the inclusive reporting window once. This produces one
    -- row of dates that is used to scope accounts and balance records below.
    SELECT 
        CAST('2026-10-01' AS DATE) AS StartDate,
        CAST('2026-10-05' AS DATE) AS EndDate
),
AccountsInScope AS (
    -- Step 2: Attach the reporting window and expected calendar-day count to
    -- every account. This preserves accounts with no balance rows for Step 3.
    SELECT 
        ba.AccountID,
        ba.CustomerID,
        rp.StartDate,
        rp.EndDate,
        DATEDIFF(DAY, rp.StartDate, rp.EndDate) + 1 AS ExpectedDays
    FROM 
        #BankAccounts ba
    CROSS JOIN 
        ReportingPeriod rp 
),
BalanceStats AS (
    -- Step 3: Keep all in-scope accounts with a LEFT JOIN, count distinct
    -- balance dates for coverage, and count extra records as duplicates.
    -- This produces one statistics row per account for classification next.
    SELECT 
        aa.AccountID,
        aa.CustomerID,
        aa.ExpectedDays,
        COUNT(DISTINCT dab.BalanceDate) AS ActualDays,
        COUNT(dab.BalanceRecordID) - COUNT(DISTINCT dab.BalanceDate) AS DuplicateRecords
    FROM 
        AccountsInScope aa
    LEFT JOIN 
        #DailyAccountBalances dab ON aa.AccountID = dab.AccountID 
            AND dab.BalanceDate BETWEEN aa.StartDate AND aa.EndDate
    GROUP BY 
        aa.AccountID, aa.CustomerID, aa.ExpectedDays
),
ValidationResults AS (
    -- Step 4: Calculate missing days and independently classify missing and
    -- duplicate issues. The final query uses NULL status to exclude clean rows.
    SELECT 
        bs.AccountID,
        bs.CustomerID,
        bs.ExpectedDays,
        bs.ActualDays,
        (bs.ExpectedDays - bs.ActualDays) AS MissingDays,
        bs.DuplicateRecords,
        CASE 
            WHEN (bs.ExpectedDays - bs.ActualDays) > 0 AND bs.DuplicateRecords > 0 THEN 'MISSING_AND_DUPLICATE'
            WHEN (bs.ExpectedDays - bs.ActualDays) > 0 THEN 'MISSING_DAYS'
            WHEN bs.DuplicateRecords > 0 THEN 'DUPLICATE_RECORDS'
            ELSE NULL
        END AS ValidationStatus
    FROM 
        BalanceStats bs
)

-- Step 5: Return only accounts with issues, in the requested account order.
SELECT 
    vr.AccountID,
    vr.CustomerID,
    vr.ExpectedDays,
    vr.ActualDays,
    vr.MissingDays,
    vr.DuplicateRecords,
    vr.ValidationStatus
FROM 
    ValidationResults vr
WHERE
    vr.ValidationStatus IS NOT NULL
ORDER BY 
    vr.AccountID;

/*

## Task 42 — Final SQL Review: Attempt 4

SQL logic score

# 10/10

Status

Logic passed

Your fourth attempt resolves all the issues identified in the previous reviews. The query is logically correct, including for accounts with zero balance records and accounts with both missing dates and multiple duplicates.

### 1. Technical validation

| Requirement                              | Assessment |
| ---------------------------------------- | ---------- |
| Inclusive reporting period               | Pass       |
| ExpectedDays calculated independently    | Pass       |
| All bank accounts preserved              | Pass       |
| Distinct balance dates counted           | Pass       |
| Duplicate records calculated             | Pass       |
| Missing dates calculated                 | Pass       |
| Both conditions classified independently | Pass       |
| Clean accounts excluded                  | Pass       |
| Correct output grain                     | Pass       |
| Deterministic ordering                   | Pass       |

### 2. Expected output

Your SQL should return these six rows using the supplied Task 42 dataset.

| AccountID | CustomerID | ExpectedDays | ActualDays | MissingDays | DuplicateRecords | ValidationStatus      |
| --------- | ---------- | ------------ | ---------- | ----------- | ---------------- | --------------------- |
| 1002      | 202        | 5            | 4          | 1           | 0                | MISSING_DAYS          |
| 1003      | 203        | 5            | 5          | 0           | 1                | DUPLICATE_RECORDS     |
| 1004      | 204        | 5            | 3          | 2           | 0                | MISSING_DAYS          |
| 1005      | 205        | 5            | 4          | 1           | 1                | MISSING_AND_DUPLICATE |
| 1007      | 207        | 5            | 1          | 4           | 0                | MISSING_DAYS          |
| 1008      | 208        | 5            | 5          | 0           | 2                | DUPLICATE_RECORDS     |

The output is predicted from the query and provided data. Actual SSMS execution has not been independently verified for Attempt 4.

### 3. What improved

A. Correct population preservation

```
FROM #BankAccounts ba
CROSS JOIN ReportingPeriod rp
```

This ensures every account receives the reporting period and expected day count, regardless of whether it has any balance records.

B. Correct placement of date filtering

```
LEFT JOIN #DailyAccountBalances dab
    ON aa.AccountID = dab.AccountID
    AND dab.BalanceDate BETWEEN aa.StartDate AND aa.EndDate
```

This is an important improvement. Keeping the date filter in `ON` preserves accounts with no matching balance records.

C. Correct classification

```
CASE
    WHEN MissingDays > 0 AND DuplicateRecords > 0
        THEN 'MISSING_AND_DUPLICATE'
    WHEN MissingDays > 0
        THEN 'MISSING_DAYS'
    WHEN DuplicateRecords > 0
        THEN 'DUPLICATE_RECORDS'
    ELSE NULL
END
```

This illustrates your implemented logic, with the two measures expressed by their calculated names.

The conditions are now based on independent validation rules rather than specific combinations in the sample data.

### 4. Correction points / learning log

| Attempt   | Score | Main issue                                            |
| --------- | ----- | ----------------------------------------------------- |
| Attempt 1 | 7/10  | CASE logic and account preservation                   |
| Attempt 2 | 8/10  | Missing NULL handling and classification edge cases   |
| Attempt 3 | 8/10  | Unnecessary customer filter; unresolved NULL handling |
| Attempt 4 | 10/10 | All identified logic issues resolved                  |

The most significant improvement is your handling of LEFT JOIN cardinality and zero-match records.

You also separated the query into distinct stages: reporting period, account population, aggregation, and validation. This makes the logic easier to test and maintain.

One observation: this fourth attempt is substantially more structured and heavily commented than your earlier versions. If you used outside assistance to construct it, that is useful for learning, but your independent proficiency should be assessed separately. The 10/10 score applies to the submitted SQL, not necessarily to unaided execution.

### 5. Git checkpoint

File: `06_Data_Engineering/task-042-customer-daily-balance-validation.sql`

```
git add 06_Data_Engineering/task-042-customer-daily-balance-validation.sql
git commit -m "Complete Task 42 customer daily balance validation"
git push
```

Task 42: SQL logic accepted — 10/10. Share the actual SSMS output if you want execution verification recorded as well.

I will not assign Task 43 until you request it.

*/