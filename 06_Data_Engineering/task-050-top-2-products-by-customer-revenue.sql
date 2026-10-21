/*

## Task 050 — Top 2 Products by Revenue per Customer

## Customer-Level Product Revenue Ranking

Database: `DataEngineeringPracticeDB_Lite`

Folder: `06_Data_Engineering`

Filename: `task-050-top-2-products-by-customer-revenue.sql`

### Business requirement

The sales analytics team wants to identify the top two products by revenue for each customer based on their order-item purchase history.

Use these tables:

- `dbo.Orders`
- `dbo.OrderItems`
- `dbo.Products`

Calculate each customer's revenue per product using:

`Quantity × UnitPrice`

Then rank products within each customer by total product revenue, highest first.

### Required output

Return exactly these six columns:

| Column          | Meaning                                                   |
| --------------- | --------------------------------------------------------- |
| `CustomerID`    | Customer identifier                                       |
| `ProductID`     | Product identifier                                        |
| `ProductName`   | Product name                                              |
| `TotalQuantity` | Total quantity purchased by the customer for that product |
| `TotalRevenue`  | Total revenue for that customer-product combination       |
| `ProductRank`   | Revenue ranking within the customer                       |

### Rules

1. Include only products that the customer has actually purchased.
2. Aggregate revenue and quantity before ranking products.
3. Return at most two products per customer.
4. If products have equal revenue, use `ProductID ASC` as the tie-breaker so the ranking is deterministic.
5. Sort the final output by `CustomerID ASC`, then `ProductRank ASC`.
6. Use a window function for ranking.
7. CTEs are allowed. Do not create permanent objects, use temporary tables, or modify source data.

### Your task

Write the SQL query independently and run it in SSMS.

Remember the important design decision from your earlier tasks: aggregate at the required business grain before applying the window function. Here, the grain is one row per customer-product combination.

Share your query first. I'll review your logic and identify what needs correction without revealing the full solution before your attempt.

*/

USE DataEngineeringPracticeDB_Lite
GO

WITH RevenueCalculation AS
(
SELECT 
	O.CustomerID,
	OI.ProductID,
	P.ProductName,
	SUM(OI.Quantity) AS TotalQuantity,
	SUM(OI.Quantity * OI.UnitPrice) AS TotalRevenue
FROM OrderItems OI
LEFT JOIN Orders O
	ON OI.OrderID = O.OrderID
LEFT JOIN Products P
	ON OI.ProductID = P.ProductID
GROUP BY 
	O.CustomerID,
	OI.ProductID,
	P.ProductName
),
RANKING AS
(
SELECT 
	
	R.CustomerID,
	R.ProductID,
	R.ProductName,
	R.TotalQuantity,
	R.TotalRevenue,
	ROW_NUMBER() OVER(PARTITION BY R.CustomerID ORDER BY R.TotalRevenue DESC, R.productID ASC) AS ProductRank
FROM RevenueCalculation R
)

SELECT	
	R.CustomerID,
	R.ProductID,
	R.ProductName,
	R.TotalQuantity,
	R.TotalRevenue,
	R.ProductRank
FROM RANKING R
WHERE ProductRank IN (1,2)
ORDER BY 
	R.CustomerID ASC,
	R.ProductRank ASC

/*

## Task 050 — Final Assessment

Status:&#x20;

Query logic validated



Your diagnostic output explains why you see only one product per customer: each of the 10 customers has purchased exactly one distinct product in `DataEngineeringPracticeDB_Lite`.

| Validation                        | Result    |
| --------------------------------- | --------- |
| Customers checked                 | 10        |
| Distinct products per customer    | 1 each    |
| Product aggregation               | Correct   |
| Revenue calculation               | Correct   |
| Ranking logic                     | Correct   |
| Maximum two products per customer | Satisfied |

Your query is behaving as expected. `ROW_NUMBER()` cannot produce a second-ranked product when there is only one product for a customer.

### What you learned

The most important lesson is to distinguish between a SQL logic problem and a data limitation. Your query was designed to return the top two products, but the available data contains only one distinct product per customer. The output therefore reflects the data, not a ranking error.

For a stronger test of Task 050, you would need customers with multiple purchased products. You can then verify that the highest-revenue product gets rank 1 and the next-highest gets rank 2.

### Final task record

- Task: 050 — Top 2 Products by Revenue per Customer
- Filename: `task-050-top-2-products-by-customer-revenue.sql`
- Folder: `06_Data_Engineering`
- Git status: Commit and push not confirmed.

```
git add 06_Data_Engineering/task-050-top-2-products-by-customer-revenue.sql
git commit -m "Complete task 050: top products by customer revenue"
git push origin main
```

Task 050 is complete from a query-logic perspective. Multi-product ranking has not been empirically tested because the current dataset does not contain multiple purchased products per customer.

*/