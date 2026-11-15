/*

## SQL Practice — Task 44

Task 44

SQL Server 2022

Data Engineering

Database: `DataEngineeringPracticeDB_Lite`

Save file: `06_Data_Engineering/task-044-banking-transaction-running-balance.sql`

### 1. Business requirement

A bank receives daily debit and credit transactions for multiple customer accounts.

The Data Engineering team must generate an account-level transaction ledger showing the running balance after each transaction.

Each account has an opening balance. Transactions must be processed in chronological order.

Your query must return one row per transaction, showing the account's balance immediately after that transaction.

Business rules:

1. Every account begins with its assigned `OpeningBalance`.
2. `CREDIT` transactions increase the balance.
3. `DEBIT` transactions decrease the balance.
4. Transactions must be processed in ascending `TransactionDate` order.
5. When two transactions have the same timestamp, the smaller `TransactionID` must be processed first.
6. Each account's running balance must be calculated independently.
7. Accounts without transactions must not appear in the transaction ledger.

### 2. Dataset — Execute in SSMS

```

USE DataEngineeringPracticeDB_Lite;
GO

DROP TABLE IF EXISTS #BankTransactions;
DROP TABLE IF EXISTS #AccountOpeningBalances;

CREATE TABLE #AccountOpeningBalances (
    AccountID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    OpeningBalance DECIMAL(14,2) NOT NULL
);

CREATE TABLE #BankTransactions (
    TransactionID INT PRIMARY KEY,
    AccountID INT NOT NULL,
    TransactionDate DATETIME2(0) NOT NULL,
    TransactionType VARCHAR(10) NOT NULL,
    Amount DECIMAL(14,2) NOT NULL
);

INSERT INTO #AccountOpeningBalances VALUES
(1001,201,10000.00),
(1002,202,20000.00),
(1003,203,5000.00),
(1004,204,15000.00),
(1005,205,8000.00);

INSERT INTO #BankTransactions VALUES
(101,1001,'2026-11-01 09:00:00','CREDIT',5000.00),
(102,1001,'2026-11-01 10:00:00','DEBIT',2000.00),
(103,1001,'2026-11-01 10:00:00','CREDIT',1000.00),
(104,1001,'2026-11-02 11:00:00','DEBIT',3000.00),

(105,1002,'2026-11-01 09:30:00','DEBIT',5000.00),
(106,1002,'2026-11-01 12:00:00','CREDIT',10000.00),
(107,1002,'2026-11-02 09:00:00','DEBIT',7000.00),

(108,1003,'2026-11-01 08:00:00','CREDIT',2000.00),
(109,1003,'2026-11-01 08:00:00','DEBIT',1000.00),
(110,1003,'2026-11-03 15:00:00','CREDIT',3000.00),

(111,1004,'2026-11-02 10:00:00','DEBIT',4000.00),
(112,1004,'2026-11-02 11:00:00','DEBIT',2000.00),
(113,1004,'2026-11-02 12:00:00','CREDIT',5000.00);

-- Account 1005 intentionally has no transactions.

```

### 3. Required output

Return these columns in the specified order:

`AccountID`, `CustomerID`, `TransactionID`, `TransactionDate`, `TransactionType`, `Amount`, `OpeningBalance`, `RunningBalance`.

Sort the final result by `AccountID`, `TransactionDate`, and `TransactionID`, all ascending.

### 4. Expected output

13 rows. All amounts are in INR.

| AccountID | CustomerID | TransactionID | TransactionDate     | TransactionType | Amount   | OpeningBalance | RunningBalance |
| --------- | ---------- | ------------- | ------------------- | --------------- | -------- | -------------- | -------------- |
| 1001      | 201        | 101           | 2026-11-01 09:00:00 | CREDIT          | 5000.00  | 10000.00       | 15000.00       |
| 1001      | 201        | 102           | 2026-11-01 10:00:00 | DEBIT           | 2000.00  | 10000.00       | 13000.00       |
| 1001      | 201        | 103           | 2026-11-01 10:00:00 | CREDIT          | 1000.00  | 10000.00       | 14000.00       |
| 1001      | 201        | 104           | 2026-11-02 11:00:00 | DEBIT           | 3000.00  | 10000.00       | 11000.00       |
| 1002      | 202        | 105           | 2026-11-01 09:30:00 | DEBIT           | 5000.00  | 20000.00       | 15000.00       |
| 1002      | 202        | 106           | 2026-11-01 12:00:00 | CREDIT          | 10000.00 | 20000.00       | 25000.00       |
| 1002      | 202        | 107           | 2026-11-02 09:00:00 | DEBIT           | 7000.00  | 20000.00       | 18000.00       |
| 1003      | 203        | 108           | 2026-11-01 08:00:00 | CREDIT          | 2000.00  | 5000.00        | 7000.00        |
| 1003      | 203        | 109           | 2026-11-01 08:00:00 | DEBIT           | 1000.00  | 5000.00        | 6000.00        |
| 1003      | 203        | 110           | 2026-11-03 15:00:00 | CREDIT          | 3000.00  | 5000.00        | 9000.00        |
| 1004      | 204        | 111           | 2026-11-02 10:00:00 | DEBIT           | 4000.00  | 15000.00       | 11000.00       |
| 1004      | 204        | 112           | 2026-11-02 11:00:00 | DEBIT           | 2000.00  | 15000.00       | 9000.00        |
| 1004      | 204        | 113           | 2026-11-02 12:00:00 | CREDIT          | 5000.00  | 15000.00       | 14000.00       |

### 5. Acceptance criteria

Your SQL must:

- Return exactly 13 transaction records.
- Calculate the correct running balance for each account.
- Reset the running calculation for each account.
- Handle identical transaction timestamps using `TransactionID` as the tie-breaker.
- Preserve the opening balance in every transaction row.
- Exclude AccountID `1005`, which has no transactions.
- Return the columns and sorting exactly as specified.

### 6. Submission instructions

Write the SQL independently and submit your query along with the SSMS result.

I will assess correctness, ordering, transaction-level grain, and running-balance calculations out of 10.

No hints or solution are provided before your first attempt. After successful validation, I will provide your learning log and Git commands.

*/

-- `AccountID`, `CustomerID`, `TransactionID`, `TransactionDate`, `TransactionType`, `Amount`, `OpeningBalance`, `RunningBalance`

SELECT
    T.AccountID,
    O.CustomerID,
    T.TransactionID,
    T.TransactionDate,
    T.TransactionType,
    T.Amount,
    O.OpeningBalance,
    SUM(CASE 
            WHEN T.TransactionType = 'CREDIT' THEN T.Amount 
            WHEN T.TransactionType = 'DEBIT' THEN -T.Amount 
        END) OVER (PARTITION BY t.AccountID ORDER BY t.TransactionDate, t.TransactionID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) + O.OpeningBalance AS RunningBalance
FROM #BankTransactions T
INNER JOIN #AccountOpeningBalances O
ON T.AccountID = O.AccountID
ORDER BY
    T.AccountID,
    T.TransactionDate,
    T.TransactionID;

/*

## **Task 44 — Banking Transaction Running Balance: SQL Review**

SQL logic score

# **10/10**

Status

Logic passed

Your first attempt is **fully correct**. You have correctly implemented an account-level running balance using a window function, conditional transaction amounts, and the account opening balance.

### **1. Technical validation**

| Requirement                           | Assessment |
| ------------------------------------- | ---------- |
| Correct account-level partitioning    | Pass       |
| CREDIT increases balance              | Pass       |
| DEBIT decreases balance               | Pass       |
| Opening balance included              | Pass       |
| Transaction date ordering             | Pass       |
| TransactionID tie-breaker             | Pass       |
| Explicit window frame                 | Pass       |
| Correct JOIN                          | Pass       |
| Account without transactions excluded | Pass       |
| Final output ordering                 | Pass       |

### **2. Most important part of your query**

```
SUM(
    CASE
        WHEN T.TransactionType = 'CREDIT' THEN T.Amount
        WHEN T.TransactionType = 'DEBIT' THEN -T.Amount
        ELSE 0
    END
) OVER (
    PARTITION BY T.AccountID
    ORDER BY T.TransactionDate, T.TransactionID
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) + O.OpeningBalance AS RunningBalance
```

You have correctly combined three concepts:

- `PARTITION BY T.AccountID` — calculates each account independently.
- `ORDER BY T.TransactionDate, T.TransactionID` — processes transactions in the required sequence.
- `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` — accumulates transaction amounts from the first transaction through the current transaction.

Adding `O.OpeningBalance` converts the cumulative transaction movement into the actual account balance.

### **3. Expected result verification**

Your query should produce the following running balances:

| AccountID | TransactionID | RunningBalance |
| --------- | ------------- | -------------- |
| 1001      | 101           | 15,000.00      |
| 1001      | 102           | 13,000.00      |
| 1001      | 103           | 14,000.00      |
| 1001      | 104           | 11,000.00      |
| 1002      | 105           | 15,000.00      |
| 1002      | 106           | 25,000.00      |
| 1002      | 107           | 18,000.00      |
| 1003      | 108           | 7,000.00       |
| 1003      | 109           | 6,000.00       |
| 1003      | 110           | 9,000.00       |
| 1004      | 111           | 11,000.00      |
| 1004      | 112           | 9,000.00       |
| 1004      | 113           | 14,000.00      |

These are calculated from the supplied dataset. Your actual SSMS output has not yet been submitted.

### **4. Correction points / learning log**

| Skill                               | Assessment |
| ----------------------------------- | ---------- |
| Business requirement interpretation | Excellent  |
| Window aggregation                  | Correct    |
| Partitioning                        | Correct    |
| Ordering and tie-breaking           | Correct    |
| Explicit window framing             | Correct    |
| Financial transaction logic         | Correct    |
| Query readability                   | Good       |

**Important learning:** Your use of `ROWS` rather than relying on SQL Server's default window frame is particularly appropriate. It ensures row-by-row accumulation, including when multiple transactions share the same timestamp.

One production consideration: the `ELSE 0` clause treats unexpected transaction types as zero movement. In a banking pipeline, invalid transaction types should generally be flagged for data-quality review rather than silently ignored.

### **5. Git checkpoint**

**Save file:** `06_Data_Engineering/task-044-banking-transaction-running-balance.sql`

Once you verify the output in SSMS:

```
git add 06_Data_Engineering/task-044-banking-transaction-running-balance.sql
git commit -m "Complete Task 44 banking transaction running balance"
git push
```

### **Final assessment**

**Task 44: 10/10 for SQL logic — passed on the first attempt.**

This is a strong example of correctly translating a banking ledger requirement into SQL window-function logic.

Share your SSMS output to complete execution verification. I will not assign Task 45 until you explicitly request it.

*/