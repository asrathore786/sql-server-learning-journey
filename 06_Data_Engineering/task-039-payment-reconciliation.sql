/*

## SQL Task 39 — Banking Payment Reconciliation

Intermediate–Advanced

SQL Server 2022 · Data Engineering · Financial Reconciliation

File: `06_Data_Engineering/task-039-payment-reconciliation.sql`\
Database: `DataEngineeringPracticeDB_Lite`\
Practice tables: `#CoreBankingPayments`, `#PaymentGatewaySettlements`

### 1. Business requirement

A bank processes customer payments through its Core Banking System (CBS). A separate payment gateway provides settlement records for the same transactions.

At the end of each business day, the Finance and Reconciliation team must identify discrepancies between the two systems.

Your task is to develop a SQL query that classifies each payment into one of four reconciliation statuses.

| Reconciliation status | Business rule                                        |
| --------------------- | ---------------------------------------------------- |
| `Matched`             | Payment exists in both systems and amounts are equal |
| `Amount Mismatch`     | Payment exists in both systems but amounts differ    |
| `Missing in Gateway`  | Payment exists in CBS but not in the gateway         |
| `Missing in CBS`      | Payment exists in the gateway but not in CBS         |

### 2. Dataset setup

Execute this independent dataset in SSMS.

```
USE DataEngineeringPracticeDB_Lite;
GO

DROP TABLE IF EXISTS #CoreBankingPayments;
DROP TABLE IF EXISTS #PaymentGatewaySettlements;

CREATE TABLE #CoreBankingPayments
(
    PaymentID INT PRIMARY KEY,
    CustomerID VARCHAR(10) NOT NULL,
    PaymentAmount DECIMAL(18,2) NOT NULL,
    PaymentDate DATE NOT NULL
);

CREATE TABLE #PaymentGatewaySettlements
(
    SettlementID INT PRIMARY KEY,
    PaymentID INT NOT NULL UNIQUE,
    SettledAmount DECIMAL(18,2) NOT NULL,
    SettlementDate DATE NOT NULL
);

INSERT INTO #CoreBankingPayments
(
    PaymentID,
    CustomerID,
    PaymentAmount,
    PaymentDate
)
VALUES
(101, 'C101', 5000.00, '2026-10-25'),
(102, 'C102', 3000.00, '2026-10-25'),
(103, 'C103', 7500.00, '2026-10-25'),
(104, 'C104', 2000.00, '2026-10-25'),
(105, 'C105', 9000.00, '2026-10-25'),
(106, 'C106', 4500.00, '2026-10-25'),
(107, 'C107', 6000.00, '2026-10-25'),
(108, 'C108', 1200.00, '2026-10-25');

INSERT INTO #PaymentGatewaySettlements
(
    SettlementID,
    PaymentID,
    SettledAmount,
    SettlementDate
)
VALUES
(1001, 101, 5000.00, '2026-10-25'),
(1002, 102, 3000.00, '2026-10-25'),
(1003, 103, 7000.00, '2026-10-25'),
(1004, 105, 9000.00, '2026-10-25'),
(1005, 106, 4000.00, '2026-10-25'),
(1006, 109, 2500.00, '2026-10-25'),
(1007, 110, 3500.00, '2026-10-25'),
(1008, 108, 1200.00, '2026-10-25');
```

Keep the same SSMS connection open because these are local temporary tables.

### 3. Your assignment

Write a read-only SQL query that reconciles payments between CBS and the gateway.

| #  | Acceptance criterion                                              |
| -- | ----------------------------------------------------------------- |
| 1  | Include every distinct `PaymentID` appearing in either system     |
| 2  | Match transactions using `PaymentID`                              |
| 3  | Identify matched amounts                                          |
| 4  | Identify amount mismatches                                        |
| 5  | Identify payments missing from the gateway                        |
| 6  | Identify payments missing from CBS                                |
| 7  | Preserve missing amounts as `NULL`; do not replace them with zero |
| 8  | Return exactly one row per distinct `PaymentID`                   |
| 9  | Sort by `PaymentID ASC`                                           |
| 10 | Do not modify either source table                                 |

### 4. Required output structure

| Column               | Description                                 |
| -------------------- | ------------------------------------------- |
| PaymentID            | Unique payment identifier                   |
| CustomerID           | Customer from CBS; `NULL` if missing in CBS |
| CBSAmount            | Amount recorded in CBS                      |
| GatewayAmount        | Amount recorded by the gateway              |
| ReconciliationStatus | One of the four defined statuses            |

Expected result values are intentionally withheld until you submit your SQL.

### 5. Evaluation criteria

Your submission will be reviewed for reconciliation completeness, join cardinality, correct handling of missing records, amount comparison, output grain, and SQL Server compatibility.

Your turn: Execute the setup script and submit your SQL query with its SSMS output. I will review the query first, then provide the expected results, score, correction points, and Git commands after successful completion.

I will not assign Task 40 until you explicitly request it.

*/


--SELECT * FROM #CoreBankingPayments
--SELECT * FROM #PaymentGatewaySettlements


SELECT 
    P.PaymentID,
    C.CustomerID,
    COALESCE(C.PaymentAmount,0) AS CBSAmount,
    COALESCE(P.SettledAmount,0) AS GatewayAmount,
    CASE
        WHEN P.PaymentID = C.PaymentID AND C.PaymentAmount = P.SettledAmount THEN 'Matched'
        WHEN P.PaymentID = C.PaymentID AND C.PaymentAmount <> P.SettledAmount THEN 'Amount Mismatch'
        WHEN P.PaymentID IS NULL THEN 'Missing in Gateway'
        WHEN C.PaymentID IS NULL THEN 'Missing in CBS'
    END AS ReconciliationStatus
FROM #PaymentGatewaySettlements P
FULL OUTER JOIN #CoreBankingPayments C
    ON C.PaymentID = P.PaymentID
