
/*
============================================================
Database: DataEngineeringPracticeDB
Purpose: SQL, analytics and Data Engineering practice
SQL Server 2022+
============================================================

Creates a separate database. Does not modify PracticeDatabase.
Sample data is generated deterministically.
*/

USE master;
GO

IF DB_ID(N'DataEngineeringPracticeDB') IS NULL
BEGIN
    CREATE DATABASE DataEngineeringPracticeDB;
END;
GO

USE DataEngineeringPracticeDB;
GO

SET NOCOUNT ON;
GO

/*============================================================
  1. CREATE TABLES
============================================================*/

IF OBJECT_ID('dbo.Customers', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Customers
    (
        CustomerID   INT PRIMARY KEY,
        CustomerName VARCHAR(100) NOT NULL,
        City         VARCHAR(50) NOT NULL,
        SignupDate   DATE NOT NULL,
        CustomerType VARCHAR(20) NOT NULL
    );
END;
GO

IF OBJECT_ID('dbo.Products', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Products
    (
        ProductID   INT PRIMARY KEY,
        ProductName VARCHAR(100) NOT NULL,
        Category    VARCHAR(50) NOT NULL,
        UnitPrice   DECIMAL(12,2) NOT NULL
    );
END;
GO

IF OBJECT_ID('dbo.Orders', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Orders
    (
        OrderID     INT PRIMARY KEY,
        CustomerID  INT NOT NULL,
        OrderDate   DATE NOT NULL,
        Status      VARCHAR(20) NOT NULL,
        TotalAmount DECIMAL(14,2) NOT NULL DEFAULT 0,

        CONSTRAINT FK_Orders_Customers
            FOREIGN KEY (CustomerID)
            REFERENCES dbo.Customers(CustomerID)
    );
END;
GO

IF OBJECT_ID('dbo.OrderItems', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.OrderItems
    (
        OrderItemID INT PRIMARY KEY,
        OrderID     INT NOT NULL,
        ProductID   INT NOT NULL,
        Quantity    INT NOT NULL,
        UnitPrice   DECIMAL(12,2) NOT NULL,

        CONSTRAINT FK_OrderItems_Orders
            FOREIGN KEY (OrderID)
            REFERENCES dbo.Orders(OrderID),

        CONSTRAINT FK_OrderItems_Products
            FOREIGN KEY (ProductID)
            REFERENCES dbo.Products(ProductID)
    );
END;
GO

IF OBJECT_ID('dbo.Payments', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Payments
    (
        PaymentID     INT PRIMARY KEY,
        OrderID       INT NOT NULL,
        PaymentDate   DATE NOT NULL,
        PaymentMethod VARCHAR(30) NOT NULL,
        PaymentStatus VARCHAR(20) NOT NULL,
        PaymentAmount DECIMAL(14,2) NOT NULL,

        CONSTRAINT FK_Payments_Orders
            FOREIGN KEY (OrderID)
            REFERENCES dbo.Orders(OrderID)
    );
END;
GO

/*============================================================
  2. GENERATE CUSTOMERS: 500 ROWS
============================================================*/

IF NOT EXISTS (SELECT 1 FROM dbo.Customers)
BEGIN
    ;WITH N AS
    (
        SELECT TOP (500)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects a
        CROSS JOIN sys.all_objects b
    )
    INSERT INTO dbo.Customers
    (
        CustomerID, CustomerName, City, SignupDate, CustomerType
    )
    SELECT
        n,
        CONCAT('Customer ', RIGHT('0000' + CAST(n AS VARCHAR(4)), 4)),
        CASE n % 10
            WHEN 0 THEN 'Delhi'
            WHEN 1 THEN 'Mumbai'
            WHEN 2 THEN 'Bengaluru'
            WHEN 3 THEN 'Hyderabad'
            WHEN 4 THEN 'Pune'
            WHEN 5 THEN 'Jaipur'
            WHEN 6 THEN 'Agra'
            WHEN 7 THEN 'Chennai'
            WHEN 8 THEN 'Lucknow'
            ELSE 'Kolkata'
        END,
        DATEADD(DAY, (n * 13) % 1400, '20230101'),
        CASE
            WHEN n % 10 < 3 THEN 'Premium'
            WHEN n % 10 < 7 THEN 'Regular'
            ELSE 'New'
        END
    FROM N;
END;
GO

/*============================================================
  3. GENERATE PRODUCTS: 100 ROWS
============================================================*/

IF NOT EXISTS (SELECT 1 FROM dbo.Products)
BEGIN
    ;WITH N AS
    (
        SELECT TOP (100)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects a
        CROSS JOIN sys.all_objects b
    )
    INSERT INTO dbo.Products
    (
        ProductID, ProductName, Category, UnitPrice
    )
    SELECT
        n,
        CONCAT('Product ', RIGHT('000' + CAST(n AS VARCHAR(3)), 3)),
        CASE n % 6
            WHEN 0 THEN 'Electronics'
            WHEN 1 THEN 'Home'
            WHEN 2 THEN 'Clothing'
            WHEN 3 THEN 'Grocery'
            WHEN 4 THEN 'Office'
            ELSE 'Accessories'
        END,
        CAST(100 + ((n * 137) % 49000) / 100.0 AS DECIMAL(12,2))
    FROM N;
END;
GO

/*============================================================
  4. GENERATE ORDERS: 10,000 ROWS
============================================================*/

IF NOT EXISTS (SELECT 1 FROM dbo.Orders)
BEGIN
    ;WITH N AS
    (
        SELECT TOP (10000)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects a
        CROSS JOIN sys.all_objects b
    )
    INSERT INTO dbo.Orders
    (
        OrderID, CustomerID, OrderDate, Status, TotalAmount
    )
    SELECT
        n,
        ((n * 17 + 13) % 500) + 1,
        DATEADD
        (
            DAY,
            (n * 37 + (n % 13) * 11) % 1400,
            '20230101'
        ),
        CASE n % 10
            WHEN 0 THEN 'Cancelled'
            WHEN 1 THEN 'Pending'
            WHEN 2 THEN 'Returned'
            ELSE 'Completed'
        END,
        0
    FROM N;
END;
GO

/*============================================================
  5. GENERATE ORDER ITEMS
  Each order receives between 1 and 4 items.
============================================================*/

IF NOT EXISTS (SELECT 1 FROM dbo.OrderItems)
BEGIN
    INSERT INTO dbo.OrderItems
    (
        OrderItemID, OrderID, ProductID, Quantity, UnitPrice
    )
    SELECT
        (O.OrderID - 1) * 4 + V.ItemNumber,
        O.OrderID,
        ((O.OrderID * 7 + V.ItemNumber * 13) % 100) + 1,
        ((O.OrderID + V.ItemNumber) % 5) + 1,
        P.UnitPrice
    FROM dbo.Orders O
    CROSS JOIN
    (
        VALUES (1), (2), (3), (4)
    ) V(ItemNumber)
    INNER JOIN dbo.Products P
        ON P.ProductID =
           ((O.OrderID * 7 + V.ItemNumber * 13) % 100) + 1
    WHERE V.ItemNumber <= 1 + (O.OrderID % 4);
END;
GO

/*============================================================
  6. UPDATE ORDER TOTALS FROM LINE ITEMS
============================================================*/

UPDATE O
SET O.TotalAmount = X.OrderTotal
FROM dbo.Orders O
INNER JOIN
(
    SELECT
        OrderID,
        SUM(Quantity * UnitPrice) AS OrderTotal
    FROM dbo.OrderItems
    GROUP BY OrderID
) X
    ON X.OrderID = O.OrderID;
GO

/*============================================================
  7. GENERATE PAYMENTS
  Some records intentionally have pending/failed statuses
  or amount differences for reconciliation practice.
============================================================*/

IF NOT EXISTS (SELECT 1 FROM dbo.Payments)
BEGIN
    INSERT INTO dbo.Payments
    (
        PaymentID,
        OrderID,
        PaymentDate,
        PaymentMethod,
        PaymentStatus,
        PaymentAmount
    )
    SELECT
        O.OrderID,
        O.OrderID,
        DATEADD(DAY, O.OrderID % 5, O.OrderDate),
        CASE O.OrderID % 4
            WHEN 0 THEN 'Card'
            WHEN 1 THEN 'UPI'
            WHEN 2 THEN 'Bank Transfer'
            ELSE 'Wallet'
        END,
        CASE
            WHEN O.OrderID % 19 = 0 THEN 'Failed'
            WHEN O.OrderID % 11 = 0 THEN 'Pending'
            ELSE 'Completed'
        END,
        CAST
        (
            CASE
                WHEN O.OrderID % 17 = 0
                    THEN O.TotalAmount * 0.90
                ELSE O.TotalAmount
            END
            AS DECIMAL(14,2)
        )
    FROM dbo.Orders O;
END;
GO

/*============================================================
  8. BASIC VALIDATION
============================================================*/

SELECT 'Customers' AS TableName, COUNT_BIG(*) AS RowCount
FROM dbo.Customers
UNION ALL
SELECT 'Products', COUNT_BIG(*) FROM dbo.Products
UNION ALL
SELECT 'Orders', COUNT_BIG(*) FROM dbo.Orders
UNION ALL
SELECT 'OrderItems', COUNT_BIG(*) FROM dbo.OrderItems
UNION ALL
SELECT 'Payments', COUNT_BIG(*) FROM dbo.Payments;
GO

SELECT TOP (10) *
FROM dbo.Orders
ORDER BY OrderDate DESC, OrderID DESC;
GO


SELECT 'Customers' AS TableName, COUNT_BIG(*) AS TotalRows
FROM dbo.Customers

UNION ALL

SELECT 'Products', COUNT_BIG(*)
FROM dbo.Products

UNION ALL

SELECT 'Orders', COUNT_BIG(*)
FROM dbo.Orders

UNION ALL

SELECT 'OrderItems', COUNT_BIG(*)
FROM dbo.OrderItems

UNION ALL

SELECT 'Payments', COUNT_BIG(*)
FROM dbo.Payments;
GO


USE DataEngineeringPracticeDB;
GO

-- Check for orders without a matching customer
SELECT COUNT(*) AS OrdersWithoutCustomer
FROM dbo.Orders O
LEFT JOIN dbo.Customers C
    ON C.CustomerID = O.CustomerID
WHERE C.CustomerID IS NULL;

-- Check for order items without a matching order
SELECT COUNT(*) AS ItemsWithoutOrder
FROM dbo.OrderItems OI
LEFT JOIN dbo.Orders O
    ON O.OrderID = OI.OrderID
WHERE O.OrderID IS NULL;

-- Check for payments without a matching order
SELECT COUNT(*) AS PaymentsWithoutOrder
FROM dbo.Payments P
LEFT JOIN dbo.Orders O
    ON O.OrderID = P.OrderID
WHERE O.OrderID IS NULL;
