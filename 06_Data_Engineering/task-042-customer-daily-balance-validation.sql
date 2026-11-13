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
    DATEDIFF(Day,'2026-10-01','2026-10-05') + 1 AS ExpectedDays,
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
            D.ExpectedDays != D.WithDuplicate AND D.ActualDays < D.ExpectedDays THEN 'MISSING_AND_DUPLICATE'
    END AS ValidationStatus
FROM #BankAccounts B
LEFT JOIN DaysCount D
    ON B.AccountID = D.AccountID
WHERE D.ExpectedDays - D.ActualDays =D.ExpectedDays 0 AND D.ActualDays = 0
AND B.CustomerID IS NOT NULL
ORDER BY D.AccountID ASC


--| AccountID | CustomerID | ExpectedDays | ActualDays | MissingDays | DuplicateRecords | ValidationStatus      |
--| --------- | ---------- | ------------ | ---------- | ----------- | ---------------- | --------------------- |
--| 1002      | 202        | 5            | 4          | 1           | 0                | MISSING_DAYS          |
--| 1003      | 203        | 5            | 5          | 0           | 1                | DUPLICATE_RECORDS     |
--| 1004      | 204        | 5            | 3          | 2           | 0                | MISSING_DAYS          |
--| 1005      | 205        | 5            | 4          | 1           | 1                | MISSING_AND_DUPLICATE |
--| 1007      | 207        | 5            | 1          | 4           | 0                | MISSING_DAYS          |
--| 1008      | 208        | 5            | 5          | 0           | 2                | DUPLICATE_RECORDS     |

