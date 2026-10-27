
/*## Task 28 — Expected SQL Result ✅

Task: Count the latest successful payments for each customer.

Using the original seven records in `PaymentStatusHistory_Q28`, your corrected SQL should return:

| CustomerID | SuccessfulPaymentCount |
| ---------- | ---------------------- |
| C1         | 1                      |
| C2         | 2                      |

Total currently successful payments: 3

### Payment-level verification

| PaymentID | CustomerID | Latest Status | Counted? |
| --------- | ---------- | ------------- | -------- |
| 101       | C1         | Success       | Yes      |
| 102       | C1         | Failed        | No       |
| 103       | C2         | Success       | Yes      |
| 104       | C2         | Success       | Yes      |

Assessment: Your final Task 28 query is logically correct and should produce the expected result above.

Note: If you inserted the additional `Success` record for PaymentID 102 at 11:30, the result changes to C1 = 2, C2 = 2.

These are calculated expected results, not output independently verified from your SSMS database.

*/


SELECT a.CustomerID,
COUNT(a.CustomerID) SuccessfulPaymentCount
FROM 
(
SELECT
	CustomerID,
	PaymentStatus,
	Row_Number() OVER(PARTITION BY paymentID ORDER BY UpdatedAt DESC) AS RN
FROM PaymentStatusHistory_Q28
) a

WHERE Paymentstatus = 'Success'
AND RN = 1
GROUP BY 
	a.CustomerID


/*## Task 28 — File Saving & Git Details

Folder: `06_Data_Engineering/`

SQL file: `task-028-latest-successful-payments.sql`

Database: `DataEngineeringPracticeDB_Lite`

Table: `dbo.PaymentStatusHistory_Q28`

### 1. Final SQL query to save

This is your successfully corrected solution, formatted for readability.

```

USE DataEngineeringPracticeDB_Lite;
GO

-- Task 28: Count currently successful payments
-- for each customer using latest payment status.

SELECT
    a.CustomerID,
    COUNT(a.CustomerID) AS SuccessfulPaymentCount
FROM
(
    SELECT
        CustomerID,
        PaymentStatus,
        ROW_NUMBER() OVER (
            PARTITION BY PaymentID
            ORDER BY UpdatedAt DESC
        ) AS RN
    FROM dbo.PaymentStatusHistory_Q28
) AS a
WHERE a.PaymentStatus = 'Success'
  AND a.RN = 1
GROUP BY a.CustomerID;

```

### 2. Expected output

| CustomerID | SuccessfulPaymentCount |
| ---------- | ---------------------- |
| C1         | 1                      |
| C2         | 2                      |

### 3. Save in VS Code

1. Open your SQL practice Git repository in VS Code.
2. Open the `06_Data_Engineering` folder (create it if it doesn't exist).
3. Create `task-028-latest-successful-payments.sql`.
4. Paste the final SQL query and save with `Ctrl + S`.
5. Execute the query in SSMS and compare its output with the expected result.

### 4. Git commands

Run these commands from the root of your Git repository:

```
git status
git add 06_Data_Engineering/task-028-latest-successful-payments.sql
git commit -m "Task 28: Latest successful payments per customer"
git push
```

If you also want to version-control your Q28 test-data setup script, stage it separately or together with the solution.

### 5. Learning log

Task 28 — Passed (10/10 logical review).

Initial mistakes corrected: incorrect partition grain, premature status filtering, and missing `RN = 1` filter.

Concepts demonstrated: `ROW_NUMBER()`, derived tables, latest-record selection, filtering after ranking, and customer-level aggregation.

Next: Task 29 — Customers with zero successful payments, after you confirm Task 28 executes successfully in SSMS.

*/