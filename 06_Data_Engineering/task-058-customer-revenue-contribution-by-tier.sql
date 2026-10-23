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
/*

## Task 058 — Query review

Status: Logically correct, and the output is consistent with the expected calculations. Your latest version fixes the denominator issue and uses `100.0` to ensure decimal arithmetic for the percentages.

### 1. Output validation

| Validation            | Your result | Assessment |
| --------------------- | ----------- | ---------- |
| Total customers       | 20          | ✅          |
| Premium customers     | 4           | ✅          |
| Standard customers    | 5           | ✅          |
| Basic customers       | 9           | ✅          |
| No Revenue customers  | 2           | ✅          |
| Total company revenue | ₹410,500.00 | ✅          |
| Premium tier revenue  | ₹306,000.00 | ✅          |
| Standard tier revenue | ₹79,000.00  | ✅          |
| Basic tier revenue    | ₹25,500.00  | ✅          |
| Sum of tier revenues  | ₹410,500.00 | ✅          |

The tier totals reconcile:

\\[ 306{,}000 + 79{,}000 + 25{,}500 = 410{,}500 \\]

Your customer contribution percentages also look correct. For example, Vihaan Rao contributes 49.02% of Premium revenue and 36.54% of total company revenue.

### 2. What you did well

- Used a `LEFT JOIN` to retain customers with no qualifying orders.
- Applied the report-date filter before aggregation, including the entire reporting date.
- Classified revenue using the correct tier boundaries.
- Used window aggregates to calculate company-wide and tier-level revenue.
- Used `NULLIF()` to avoid division-by-zero errors for the No Revenue tier.
- Applied deterministic ranking with `ROW_NUMBER()`, using revenue descending and `CustomerID` ascending as the tie-breaker.

### 3. Two refinements

First: Your current final `ORDER BY A.TierOrder` sorts tiers correctly, but it does not guarantee customer ranking order within each tier. Add `T.CustomerRankWithinTier` as a secondary sort key. Since `CustomerRankWithinTier` is calculated in the same `SELECT`, use an outer query or CTE if you want to reference that alias reliably in the final ordering.

Second: Your No Revenue customers correctly show `NULL` for `CustomerTierContributionPct` because the tier revenue denominator is zero. This is consistent with your requirement to return `NULL` when the denominator is zero.

### 4. Final task record

## Task 058 — Completed

Difficulty: Advanced · Database: DataEngineeringPracticeDB_Lite

Filename: `task-058-customer-revenue-contribution-by-tier.sql`

Folder: `06_Data_Engineering`

Key learning: Calculate window aggregates from the correct level of detail. A customer-level value, tier-level total, and company-level total are different measures; summing a higher-level total repeatedly can inflate results.

### 5. Git commands

After saving the final query in the file above, run these commands from your repository root in PowerShell:

```
git add "06_Data_Engineering/task-058-customer-revenue-contribution-by-tier.sql"
git commit -m "Complete task 058 customer revenue contribution by tier"
git push origin main
```

These commands have not been executed. Your SQL output has been reviewed based on the results you supplied; the remaining refinements are about deterministic ordering, not the revenue calculations.

*/