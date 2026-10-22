/*

## Task 058 — Customer Revenue Contribution by Tier

Filename: `task-058-customer-revenue-contribution-by-tier.sql`

Folder: `06_Data_Engineering`

Difficulty: Advanced

Database: `DataEngineeringPracticeDB_Lite`

Tables: `dbo.Customers`, `dbo.Orders`

### Business requirement

The Finance team wants to understand how much each customer contributes to their revenue tier's total revenue and to the company's overall revenue.

Using the report date 31 October 2026, prepare a customer-level report with the following requirements:

1. Include every customer, including customers with no orders on or before the report date.
2. Calculate each customer's total order revenue using only orders dated on or before the report date.
3. Classify customers into these revenue tiers:
   - Premium: total revenue greater than ₹20,000
   - Standard: ₹10,000–₹20,000 inclusive
   - Basic: greater than ₹0 but less than ₹10,000
   - No Revenue: exactly ₹0
4. For each customer, calculate:
   - `CustomerID`
   - `CustomerName`
   - `RevenueTier`
   - `CustomerRevenue`
   - `TierTotalRevenue`
   - `CustomerTierContributionPct`: the customer's percentage contribution to their own tier's total revenue.
   - `CompanyRevenueContributionPct`: the customer's percentage contribution to total company revenue.
   - `CustomerRankWithinTier`: the customer's revenue rank within their tier.
5. Rank customers by revenue in descending order within each tier. Break ties using `CustomerID` in ascending order.
6. Display percentages to two decimal places.
7. Include all customers, even when their tier has zero total revenue. In that case, return `NULL` for percentage calculations where the denominator is zero.
8. Sort the final report by tier in this order: Premium, Standard, Basic, No Revenue; then by customer rank.

### Testing data assessment

Your previous Task 057 output showed 20 customers across all four tiers. That establishes basic tier coverage, but it does not establish whether the dataset contains revenue ties or all the boundary cases required for robust testing.

Before writing the solution, inspect the existing data and determine whether additional test records are necessary. If the data is insufficient, prepare task-specific `INSERT` statements without deleting or replacing existing records. Do not execute inserts yet.

Your turn: assess the available test data, then write your SQL query. I’ll review your attempt without providing the solution first.

*/


WITH CustomerRevenue AS
(
SELECT 
	C.CustomerID,
	C.CustomerName,
	SUM(COALESCE(O.TotalAmount,0)) AS CustomerRevenue
FROM Customers C
LEFT JOIN Orders O
	ON C.CustomerID = O.CustomerID
	AND O.OrderDate < CAST('20261101' AS DATE) 
GROUP BY
	C.CustomerID,
	C.CustomerName
),
TierClassification AS
(
SELECT
	C.CustomerID,
	C.CustomerName,
	C.CustomerRevenue,
	CASE
		WHEN C.CustomerRevenue = 0 THEN 'No Revenue'
		WHEN C.CustomerRevenue > 0 AND C.CustomerRevenue < 10000 THEN 'Basic'
		WHEN C.CustomerRevenue BETWEEN 10000 AND 20000 THEN 'Standard'
		WHEN C.CustomerRevenue > 20000 THEN 'Premium'
	END AS RevenueTier
FROM CustomerRevenue C
),
ALL_Tier AS
(
SELECT RevenueTier, TierOrder
FROM (VALUES
	('No Revenue',4),
	('Basic',3),
	('Standard',2),
	('Premium',1)
	) AS Tiers (RevenueTier,TierOrder)
),
CompanyRevenue AS
(
SELECT 
	T.CustomerID,
	T.CustomerName,
	T.CustomerRevenue,
	T.RevenueTier,
	SUM(T.CustomerRevenue) OVER() AS CompanyRevenue
FROM TierClassification T
),
TierRevenue AS
(
SELECT 
	*,
	SUM(C.CustomerRevenue) OVER(PARTITION BY C.RevenueTier) TierTotalRevenue
FROM CompanyRevenue C
)
SELECT
	T.CustomerID,
	T.CustomerName,
	T.RevenueTier,
	T.CustomerRevenue,
	T.TierTotalRevenue,
	CAST(T.CustomerRevenue *100.0/  NULLIF(T.TierTotalRevenue,0) AS DECIMAL(10,2)) AS CustomerTierContributionPct,
	CAST(T.CustomerRevenue *100.0/  NULLIF(T.CompanyRevenue,0) AS DECIMAL(10,2)) AS CompanyRevenueContributionPct,
	ROW_NUMBER() OVER(PARTITION BY T.RevenueTier ORDER BY T.CustomerRevenue DESC, T.CustomerID) AS CustomerRankWithinTier
FROM TierRevenue T
LEFT JOIN ALL_Tier A
	ON A.RevenueTier = T.RevenueTier
ORDER BY 
	A.TierOrder,
	CustomerRankWithinTier