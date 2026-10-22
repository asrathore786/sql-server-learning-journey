/*

Filename: `task-057-customer-revenue-tier-distribution.sql`

Folder: `06_Data_Engineering`

Database: `DataEngineeringPracticeDB_Lite`

Difficulty: Advanced

Topic: Customer segmentation, conditional aggregation, and revenue distribution

## Business requirement

The Finance team wants to understand how customer revenue is distributed across different value tiers. They need a report showing the number of customers in each revenue tier and the percentage of the customer base represented by each tier.

Use `dbo.Customers` and `dbo.Orders`.

Apply these business rules:

- Include every customer in `dbo.Customers`, including customers who have never placed an order.
- Calculate each customer's total order value using eligible orders dated on or before 31 October 2026.
- A customer with no eligible orders must have a total order value of zero.
- Classify customers into the following tiers:

| Revenue tier | Customer total order value            |
| ------------ | ------------------------------------- |
| Premium      | Greater than ₹20,000                  |
| Standard     | ₹10,000 to ₹20,000 inclusive          |
| Basic        | Greater than ₹0 but less than ₹10,000 |
| No Revenue   | Exactly ₹0                            |

Produce one row per revenue tier, including tiers with zero customers.

Your output must contain:

| Column                   | Description                                                                    |
| ------------------------ | ------------------------------------------------------------------------------ |
| `RevenueTier`            | Customer revenue classification                                                |
| `CustomerCount`          | Number of customers in the tier                                                |
| `CustomerPercentage`     | Percentage of all customers in the tier                                        |
| `TotalTierRevenue`       | Combined order value of customers in the tier                                  |
| `AverageCustomerRevenue` | Average order value per customer in the tier, including zero-revenue customers |

Round percentage and average values to two decimal places. Display all four tiers, ordered from Premium to No Revenue.

## Testing data

The existing Lite dataset may not contain customers in every tier. Before writing your query, inspect the current data and determine whether it supports all four tiers and the required boundary cases. If it does not, prepare task-specific test inserts to cover the missing cases without replacing or deleting existing data. Include cases at exactly ₹0, ₹10,000, and ₹20,000, as well as a value just above ₹20,000.

Do not execute any inserts yet; first submit your assessment of the data coverage and your proposed setup approach.

Your task is to solve the business requirement independently. I will review your assessment first, then you can proceed with the query.

*/

WITH Customer_Summary AS
(
SELECT
	C.CustomerID,
	COALESCE(SUM(O.TotalAmount),0) AS CustomerRevenue
FROM dbo.Customers C
LEFT JOIN dbo.Orders O
	ON C.CustomerID = O.CustomerID
	AND O.OrderDate < DATEADD(DAY, 1, CAST('20261031' AS DATE))
GROUP BY C.CustomerID
),
Tier_Classification AS
(
SELECT
	CASE
		WHEN C.CustomerRevenue = 0 THEN 'No Revenue'
		WHEN C.CustomerRevenue > 0 AND C.CustomerRevenue < 10000 THEN 'Basic'
		WHEN C.CustomerRevenue BETWEEN 10000 AND 20000 THEN 'Standard'
		WHEN C.CustomerRevenue > 20000 THEN 'Premium'
	END AS RevenueTier,
	C.CustomerRevenue
FROM Customer_Summary C
),
RevenueTiers AS (
    SELECT
        RevenueTier,
        COUNT(*) AS CustomerCount,
        SUM(CustomerRevenue) AS TotalTierRevenue
    FROM Tier_Classification
    GROUP BY RevenueTier
),

ALL_Tiers AS
(
SELECT RevenueTier, TierOrder
FROM (VALUES
	('Premium',1),
	('Standard',2),
	('Basic',3),
	('No Revenue',4)
	) AS Tiers(RevenueTier, TierOrder)
)

SELECT
	T.RevenueTier,
	COALESCE(S.CustomerCount, 0) AS CustomerCount,
	CAST(COALESCE(S.CustomerCount, 0) * 100.0/ NULLIF(CAST((SELECT COUNT_BIG(*) FROM dbo.Customers) AS DECIMAL(19,2)),0)AS DECIMAL(10,2)) AS CustomerPercentage,
	COALESCE(S.TotalTierRevenue, 0) AS TotalTierRevenue,
	CAST(S.TotalTierRevenue / NULLIF(CAST(S.CustomerCount AS DECIMAL(19,2)), 0)	AS DECIMAL(10,2)
	) AS AverageCustomerRevenue
FROM ALL_Tiers T
LEFT JOIN RevenueTiers S
	ON T.RevenueTier = S.RevenueTier
ORDER BY T.TierOrder;
