/*

## **SQL Practice — Task 48**

Task 48

SQL Server 2022

Data Engineering

**Database:** `DataEngineeringPracticeDB_Lite`

**Suggested filename:** `task-048-incremental-order-data-load.sql`

**Save folder:** `06_Data_Engineering/`

### **1. Business scenario**

An e-commerce company receives daily order updates from its operational system. These records must be synchronized into a reporting database.

The source system may contain multiple versions of the same order because an order can be updated several times during the day.

Your responsibility is to build a reliable incremental data-loading process that maintains the latest valid version of each order in the reporting ta
ble.

### **2. Business requirements**

The reporting team has established the following rules:

1. The source can contain multiple records for the same `OrderID`.
2. For each `OrderID`, identify the source record with the latest `LastModifiedDate`.
3. If two source records have the same `LastModifiedDate`, select the record with the highest `SourceRecordID`.
4. If the order does not exist in the target table, insert it.
5. If the order already exists, update it only when the selected source record has a strictly newer `LastModifiedDate`.
6. If the source timestamp is older than or equal to the target timestamp, preserve the target record.
7. Orders existing only in the target must not be deleted.
8. The final target table must contain exactly one row per `OrderID`.
9. Running the synchronization a second time against unchanged source data must produce zero inserts and zero updates.
10. Do not modify the source table.

### **3. Dataset — Execute in SSMS**

```

USE DataEngineeringPracticeDB_Lite;
GO

DROP TABLE IF EXISTS #OrderSource;
DROP TABLE IF EXISTS #OrderTarget;

CREATE TABLE #OrderTarget (
    OrderID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderAmount DECIMAL(12,2) NOT NULL,
    OrderStatus VARCHAR(20) NOT NULL,
    LastModifiedDate DATETIME2(0) NOT NULL
);

CREATE TABLE #OrderSource (
    SourceRecordID INT PRIMARY KEY,
    OrderID INT NOT NULL,
    CustomerID INT NOT NULL,
    OrderAmount DECIMAL(12,2) NOT NULL,
    OrderStatus VARCHAR(20) NOT NULL,
    LastModifiedDate DATETIME2(0) NOT NULL
);

INSERT INTO #OrderTarget VALUES
(1001,201,5000,'PENDING','2026-11-01 09:00:00'),
(1002,202,3000,'COMPLETED','2026-11-02 10:00:00'),
(1003,203,4000,'PENDING','2026-11-03 11:00:00'),
(1004,204,2500,'CANCELLED','2026-11-04 12:00:00'),
(1005,205,6000,'COMPLETED','2026-11-05 13:00:00'),
(1006,206,3500,'PENDING','2026-11-06 14:00:00'),
(1007,207,2000,'COMPLETED','2026-11-07 15:00:00'),
(1008,208,4500,'PENDING','2026-11-08 16:00:00');

INSERT INTO #OrderSource VALUES
-- Multiple versions: latest version must be selected
(101,1001,201,5000,'PENDING','2026-11-09 09:00:00'),
(102,1001,201,5000,'COMPLETED','2026-11-10 10:00:00'),

-- Older source: target must remain unchanged
(103,1002,202,3000,'PENDING','2026-11-01 08:00:00'),

-- Equal timestamp: target must remain unchanged
(104,1003,203,4500,'COMPLETED','2026-11-03 11:00:00'),

-- Multiple versions with identical timestamps
(105,1004,204,2500,'PENDING','2026-11-11 09:00:00'),
(106,1004,204,2500,'COMPLETED','2026-11-11 09:00:00'),

-- Newer source
(107,1005,205,6500,'COMPLETED','2026-11-12 10:00:00'),

-- Older source
(108,1006,206,3500,'CANCELLED','2026-11-05 10:00:00'),

-- New orders
(109,1009,209,5000,'PENDING','2026-11-13 09:00:00'),
(110,1009,209,5000,'COMPLETED','2026-11-13 12:00:00'),
(111,1010,210,3000,'PENDING','2026-11-14 10:00:00'),
(112,1011,211,2500,'COMPLETED','2026-11-14 11:00:00'),

-- Existing target record with no source update: 1007, 1008
-- New order with identical source timestamps
(113,1012,212,7000,'PENDING','2026-11-15 10:00:00'),
(114,1012,212,7000,'COMPLETED','2026-11-15 10:00:00');

```

### **4. Required operations**

Write a SQL script that performs the following operations in sequence:

- Identify the single latest source record for every `OrderID`.
- Insert new orders into `#OrderTarget`.
- Update existing orders only when the selected source record is newer.
- Return the final target table sorted by `OrderID`.
- Demonstrate that a second execution of the synchronization statements produces no additional changes.

You may use multiple CTEs, temporary tables, or other SQL Server techniques. Choose the approach you consider most appropriate.

### **5. Expected output — Final target table**

Exactly 12 rows after the first synchronization.

| OrderID | CustomerID | OrderAmount | OrderStatus | LastModifiedDate    |
| ------- | ---------- | ----------- | ----------- | ------------------- |
| 1001    | 201        | 5000.00     | COMPLETED   | 2026-11-10 10:00:00 |
| 1002    | 202        | 3000.00     | COMPLETED   | 2026-11-02 10:00:00 |
| 1003    | 203        | 4000.00     | PENDING     | 2026-11-03 11:00:00 |
| 1004    | 204        | 2500.00     | COMPLETED   | 2026-11-11 09:00:00 |
| 1005    | 205        | 6500.00     | COMPLETED   | 2026-11-12 10:00:00 |
| 1006    | 206        | 3500.00     | PENDING     | 2026-11-06 14:00:00 |
| 1007    | 207        | 2000.00     | COMPLETED   | 2026-11-07 15:00:00 |
| 1008    | 208        | 4500.00     | PENDING     | 2026-11-08 16:00:00 |
| 1009    | 209        | 5000.00     | COMPLETED   | 2026-11-13 12:00:00 |
| 1010    | 210        | 3000.00     | PENDING     | 2026-11-14 10:00:00 |
| 1011    | 211        | 2500.00     | COMPLETED   | 2026-11-14 11:00:00 |
| 1012    | 212        | 7000.00     | COMPLETED   | 2026-11-15 10:00:00 |

### **6. Expected synchronization statistics**

| Metric                   | First execution | Second execution |
| ------------------------ | --------------- | ---------------- |
| New records inserted     | 4               | 0                |
| Existing records updated | 3               | 0                |
| Final target row count   | 12              | 12               |

### **7. Acceptance criteria**

Your solution must:

- Select the correct source version for every order.
- Resolve equal timestamps using `SourceRecordID`.
- Avoid primary-key violations when source records are duplicated by `OrderID`.
- Insert exactly four new orders.
- Update exactly three existing orders.
- Preserve records with older or equal source timestamps.
- Preserve target-only records.
- Produce the expected 12-row target table.
- Remain idempotent on repeated execution.

### **8. Submission and assessment**

Submit your SQL script and SSMS output. Include the insert/update counts for both executions if possible.

I will review your solution out of 10, focusing on source deduplication, incremental update conditions, join cardinality, idempotency, and output validation.

**No hints or solution before your first attempt.** Once your solution is validated, I will provide correction points, a learning log, and Git commands.

I will not automatically assign Task 49.

*/ 

--SELECT * FROM #OrderTarget
--SELECT * FROM #OrderSource

WITH SingleRecord AS
(
SELECT 
    OrderID,
    CustomerID,
    OrderAmount,
    OrderStatus,
    LastModifiedDate,
    ROW_NUMBER() OVER (PARTITION BY OrderID ORDER BY LastModifiedDate DESC,SourceRecordID) AS RNK
FROM #OrderSource S
)

INSERT INTO #OrderTarget (
    OrderID,
    CustomerID,
    OrderAmount,
    OrderStatus,
    LastModifiedDate
    )
SELECT
    OrderID,
    CustomerID,
    OrderAmount,
    OrderStatus,
    LastModifiedDate   
FROM SingleRecord S
WHERE NOT EXISTS ( SELECT 1 FROM #OrderTarget T WHERE T.OrderID = S.OrderID)
AND RNK = 1;


WITH SingleRecord AS
(
SELECT 
    OrderID,
    CustomerID,
    OrderAmount,
    OrderStatus,
    LastModifiedDate,
    ROW_NUMBER() OVER (PARTITION BY OrderID ORDER BY LastModifiedDate DESC,SourceRecordID DESC) AS RNK
FROM #OrderSource S
)
UPDATE T 
    SET
    T.OrderAmount = S.OrderAmount,
    T.OrderStatus = S.OrderStatus,
    T.LastModifiedDate = S.LastModifiedDate
FROM #OrderTarget T
INNER JOIN SingleRecord S
ON T.OrderID = S.OrderID
WHERE EXISTS ( SELECT 1 FROM #OrderTarget T WHERE T.OrderID = S.OrderID)
AND RNK = 1
AND T.LastModifiedDate < S.LastModifiedDate;


SELECT * FROM #OrderTarget