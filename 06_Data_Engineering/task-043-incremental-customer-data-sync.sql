/*

## SQL Practice — Task 43

Task 43

SQL Server 2022

Data Engineering

Database: `DataEngineeringPracticeDB_Lite`

Save file: `06_Data_Engineering/task-043-incremental-customer-data-sync.sql`

### 1. Business requirement

A bank maintains a customer master table in its Data Warehouse. Every day, an upstream CRM system sends a batch of customer records.

The Data Engineering team must synchronize the incoming data with the existing customer master.

Your responsibility is to process the incoming batch while maintaining data integrity.

Business rules:

1. If a customer does not exist in the target, insert the customer.
2. If a customer exists and the incoming `LastModifiedDate` is newer, update the customer details.
3. If the incoming record is older than or equal to the target record, retain the existing target data.
4. Do not delete customers who are absent from the incoming batch.
5. Re-running the same batch must not produce additional changes.

The incoming source contains a mixture of new, updated, unchanged, and stale customer records.

### 2. Dataset — Execute in SSMS

```

USE DataEngineeringPracticeDB_Lite;
GO

DROP TABLE IF EXISTS #CustomerSource;
DROP TABLE IF EXISTS #CustomerTarget;

CREATE TABLE #CustomerTarget (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(100) NOT NULL,
    City VARCHAR(50) NOT NULL,
    CustomerStatus VARCHAR(20) NOT NULL,
    LastModifiedDate DATETIME2(0) NOT NULL
);

CREATE TABLE #CustomerSource (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(100) NOT NULL,
    City VARCHAR(50) NOT NULL,
    CustomerStatus VARCHAR(20) NOT NULL,
    LastModifiedDate DATETIME2(0) NOT NULL
);

INSERT INTO #CustomerTarget VALUES
(101,'Amit Sharma','Delhi','Active','2026-10-20 10:00:00'),
(102,'Priya Verma','Mumbai','Active','2026-10-22 09:00:00'),
(103,'Rahul Mehta','Pune','Active','2026-10-25 12:00:00'),
(104,'Neha Singh','Jaipur','Inactive','2026-10-27 15:00:00'),
(105,'Karan Gupta','Delhi','Active','2026-10-28 11:00:00'),
(106,'Simran Kaur','Chandigarh','Active','2026-10-29 14:00:00'),
(107,'Rohit Jain','Noida','Inactive','2026-10-30 08:00:00'),
(108,'Anjali Rao','Bengaluru','Active','2026-10-31 16:00:00');

INSERT INTO #CustomerSource VALUES
-- Newer records: update target
(101,'Amit Sharma','Gurugram','Active','2026-11-02 10:00:00'),
(104,'Neha Singh','Jaipur','Active','2026-11-03 09:00:00'),
(106,'Simran Kaur','Mohali','Active','2026-11-04 11:00:00'),

-- Older records: do not update
(102,'Priya Verma','Delhi','Inactive','2026-10-20 08:00:00'),
(107,'Rohit Jain','Delhi','Active','2026-10-28 10:00:00'),

-- Same timestamp: do not update
(103,'Rahul Mehta','Nagpur','Inactive','2026-10-25 12:00:00'),

-- New customers: insert
(109,'Vikram Sethi','Lucknow','Active','2026-11-05 09:00:00'),
(110,'Pooja Nair','Kochi','Active','2026-11-05 10:00:00'),
(111,'Arjun Malhotra','Delhi','Inactive','2026-11-05 11:00:00');

-- Inspect the starting data
SELECT * FROM #CustomerTarget ORDER BY CustomerID;
SELECT * FROM #CustomerSource ORDER BY CustomerID;

```

### 3. Your assignment

Write a SQL Server script that synchronizes `#CustomerSource` into `#CustomerTarget` according to the business rules.

Your script must be safe to execute twice without producing additional inserts or updates on the second execution.

After synchronization, return the final target data ordered by `CustomerID`.

### 4. Expected output — After first execution

11 customers. All five columns must match.

| CustomerID | CustomerName   | City      | CustomerStatus | LastModifiedDate    |
| ---------- | -------------- | --------- | -------------- | ------------------- |
| 101        | Amit Sharma    | Gurugram  | Active         | 2026-11-02 10:00:00 |
| 102        | Priya Verma    | Mumbai    | Active         | 2026-10-22 09:00:00 |
| 103        | Rahul Mehta    | Pune      | Active         | 2026-10-25 12:00:00 |
| 104        | Neha Singh     | Jaipur    | Active         | 2026-11-03 09:00:00 |
| 105        | Karan Gupta    | Delhi     | Active         | 2026-10-28 11:00:00 |
| 106        | Simran Kaur    | Mohali    | Active         | 2026-11-04 11:00:00 |
| 107        | Rohit Jain     | Noida     | Inactive       | 2026-10-30 08:00:00 |
| 108        | Anjali Rao     | Bengaluru | Active         | 2026-10-31 16:00:00 |
| 109        | Vikram Sethi   | Lucknow   | Active         | 2026-11-05 09:00:00 |
| 110        | Pooja Nair     | Kochi     | Active         | 2026-11-05 10:00:00 |
| 111        | Arjun Malhotra | Delhi     | Inactive       | 2026-11-05 11:00:00 |

### 5. Expected execution validation

New inserts

# 3

Updated customers

# 3

Final target rows

# 11

| Validation        | First run | Second run |
| ----------------- | --------- | ---------- |
| Inserted rows     | 3         | 0          |
| Updated rows      | 3         | 0          |
| Deleted rows      | 0         | 0          |
| Total target rows | 11        | 11         |

### 6. Acceptance criteria

Your solution will be evaluated on:

- Correct identification of new and existing customers.
- Timestamp-based update decisions.
- Protection against stale incoming data.
- Idempotency across repeated executions.
- No unintended deletions or duplicate records.
- Accurate final output and row counts.

Important: Run the setup script only once. To test idempotency, execute your synchronization statements a second time without recreating the temporary tables.

### 7. Submission

Submit your SQL script and the final SSMS output, including the results from the second execution.

I will evaluate your solution out of 10, explain any errors, and record the correction points in your learning log.

No hints or solution are provided before your first attempt.

*/

INSERT INTO 
#CustomerTarget 
(CustomerID,CustomerName,City,CustomerStatus,LastModifiedDate)
SELECT 
    T.CustomerID,
    T.CustomerName,
    T.City,
    T.CustomerStatus,
    T.LastModifiedDate
FROM #CustomerSource T
WHERE NOT EXISTS( SELECT 1 FROM #CustomerTarget S WHERE S.CustomerID = T.CustomerID) 

UPDATE  
#CustomerTarget 
SET #CustomerTarget.LastModifiedDate = S.LastModifiedDate
FROM #CustomerTarget T
LEFT JOIN #CustomerSource S
ON S.CustomerID = T.CustomerID 
WHERE EXISTS(SELECT 1 FROM #CustomerTarget S WHERE S.CustomerID = T.CustomerID AND T.LastModifiedDate <= S.LastModifiedDate)
