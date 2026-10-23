/*

## Task 059 — Customer Revenue Concentration and Pareto Analysis

Filename: `task-059-customer-revenue-pareto-analysis.sql`

Save folder: `06_Data_Engineering`

Difficulty: Advanced

Database: `DataEngineeringPracticeDB_Lite`

### Business requirement

The Finance team wants to understand how strongly the business depends on its highest-revenue customers. Build a customer revenue concentration report as of 31 October 2026.

Include every customer, including those with zero qualifying revenue. Calculate each customer's revenue from orders placed before 1 November 2026.

Your report must show how revenue accumulates as customers are ranked from highest to lowest revenue. The Finance team will use this report to identify the smallest group of customers responsible for approximately 80% of company revenue.

### Expected output

| Column                 | Description                                                 |
| ---------------------- | ----------------------------------------------------------- |
| `CustomerID`           | Unique customer identifier                                  |
| `CustomerName`         | Customer name                                               |
| `CustomerRevenue`      | Customer's total qualifying order revenue                   |
| `CustomerRank`         | Rank by revenue, highest first                              |
| `CompanyRevenue`       | Total qualifying revenue across all customers               |
| `CustomerRevenuePct`   | Customer's percentage of company revenue                    |
| `CumulativeRevenue`    | Running revenue total in customer rank order                |
| `CumulativeRevenuePct` | Running revenue as a percentage of company revenue          |
| `ParetoCategory`       | Classify customers based on cumulative revenue contribution |

### Pareto classification rules

- Within 80%: Cumulative revenue percentage is less than or equal to 80%.
- 80–95%: Cumulative revenue percentage is greater than 80% and less than or equal to 95%.
- 95–100%: Cumulative revenue percentage is greater than 95%.
- No Revenue: Customer revenue is zero.

### Rules

1. Include all customers, even those without qualifying orders.
2. Exclude orders dated on or after 1 November 2026.
3. Calculate the running total in descending revenue order, using `CustomerID` ascending to break ties.
4. Prevent division-by-zero errors.
5. Display percentages to two decimal places.
6. Sort by customer rank, highest revenue first.
7. Do not hardcode the total company revenue or customer counts.

Your task: Write the complete SQL query and run it in SSMS. Share your query first, and I’ll review your logic before you execute it. I will not provide hints or the solution before your attempt.

*/

WITH CustomerRevenueCalculation AS
(
SELECT
	C.CustomerID,
	SUM(COALESCE(O.TotalAmount,0)) AS CustomerRevenue
FROM Customers C
LEFT JOIN Orders O
	ON O.CustomerID = C.CustomerID
	AND O.OrderDate < '20261101'
GROUP BY 
	C.CustomerID
),
Company_CustomerRevenue AS
(
SELECT
	*,
	ROW_NUMBER() OVER(ORDER BY CustomerRevenue DESC, CustomerID ASC) AS CustomerRank,
	SUM(CustomerRevenue) OVER() AS CompanyRevenue
FROM CustomerRevenueCalculation
),
CumulativeRevenueCalculation AS
(
SELECT 
	*,
	CAST
		(CustomerRevenue * 100.0
			/NULLIF(CompanyRevenue ,0) 
	AS DECIMAL(10,2)
	) AS CustomerRevenuepct,
	SUM(CustomerRevenue) OVER(ORDER BY CustomerRank ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumulativeRevenue
FROM Company_CustomerRevenue
),
CumulativePercertage AS
(
SELECT 
	*,
	CAST(CumulativeRevenue * 100.0/ NULLIF(CompanyRevenue,0) AS DECIMAL(10,2)) AS CumulativeRevenuepct
FROM CumulativeRevenueCalculation
)

SELECT 
	C.CustomerID,
	C.CustomerName,
	CP.CustomerRevenue,
	CP.CustomerRank,
	CP.CompanyRevenue,
	CP.CustomerRevenuepct,
	CP.CumulativeRevenue,
	CP.CumulativeRevenuepct,
	CASE 
		WHEN CP.CustomerRevenue = 0 OR CP.CustomerRevenue IS NULL THEN 'No Revenue'
		WHEN CP.CumulativeRevenuepct <= 80 THEN 'Within 80%'
		WHEN CP.CumulativeRevenuepct > 80 AND CP.CumulativeRevenuepct <= 95 THEN '80-95%'
		WHEN CP.CumulativeRevenuepct > 95 THEN '95-100%'
	END AS ParetoCategory
FROM Customers C
LEFT JOIN CumulativePercertage Cp
	ON Cp.CustomerID = C.CustomerID
ORDER BY 
	CP.CustomerRank ASC,
	CP.CustomerRevenue DESC

/*

## Task 059 — Final Review

Status: Correct. You fixed the 95% boundary, and your query now matches the stated business requirements.

### Final validation

| Requirement                                             | Result |
| ------------------------------------------------------- | ------ |
| Include all customers                                   | ✅      |
| Exclude orders on or after 1 November 2026              | ✅      |
| Handle customers with zero revenue                      | ✅      |
| Rank by revenue descending, then `CustomerID` ascending | ✅      |
| Calculate customer and company revenue percentages      | ✅      |
| Calculate cumulative revenue and percentage             | ✅      |
| Classify the exact 80% and 95% boundaries correctly     | ✅      |
| Prevent division-by-zero errors                         | ✅      |

Your corrected condition is:

```
WHEN CP.CumulativeRevenuepct > 80
 AND CP.CumulativeRevenuepct <= 95 THEN '80-95%'
```

This closes the gap at exactly 95%.

### One technical consideration

Your Pareto classification uses `CumulativeRevenuepct`, which is rounded to two decimal places before classification. This is consistent with the values displayed, but a value such as 80.004% would round to 80.00% and be classified as `Within 80%`. If the business requires strict thresholds on the unrounded percentage, classify using the unrounded calculation and round only for display.

For the current dataset and stated output, your logic is otherwise sound.

### Task 059 record

## Task 059 — Complete

Advanced SQL · Data Engineering

File: `06_Data_Engineering/task-059-customer-revenue-pareto-analysis.sql`

Skills demonstrated: customer-level aggregation, window functions, deterministic ranking, running totals, contribution percentages, and Pareto classification.

### Git commands

After saving the final query in the file, run these commands from your repository root:

```
git add "06_Data_Engineering/task-059-customer-revenue-pareto-analysis.sql"
git commit -m "Complete task 059 customer revenue Pareto analysis"
git push origin main
```

The commands have not been executed by me.

Assessment: You resolved the aggregation and boundary issues through successive revisions. The next improvement is to anticipate edge cases like rounded thresholds before they are pointed out. That is an important step toward independent advanced SQL problem-solving.

*/