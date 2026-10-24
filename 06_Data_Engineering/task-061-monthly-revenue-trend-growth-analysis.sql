## Task 061 — Monthly Revenue Trend and Growth Analysis

Advanced

SQL Server · Data Engineering

## Analyze Monthly Revenue Trends

Build a month-level revenue report that compares each month with the previous month and identifies revenue growth or decline.

Folder: `06_Data_Engineering`

Filename: `task-061-monthly-revenue-trend-growth-analysis.sql`

Database: `DataEngineeringPracticeDB_Lite`

Tables: `dbo.Orders`

### Business requirement

The finance team wants to understand how monthly revenue changes over time during 2026.

Write a SQL query that returns one row per month with at least one order between January 1 and December 31, 2026.

Your output must include:

1. `RevenueMonth` — month represented as the first day of that month.
2. `MonthlyRevenue` — sum of `TotalAmount` for that month.
3. `PreviousMonthRevenue` — revenue for the previous calendar month.
4. `RevenueChange` — current month's revenue minus previous month's revenue.
5. `RevenueGrowthPct` — percentage change from the previous month; return `NULL` when previous-month revenue is zero or unavailable.
6. `RevenueTrend` — classify the month as:
   - `First Month`
   - `Revenue Increased`
   - `Revenue Declined`
   - `Revenue Unchanged`
   - `No Previous Revenue` when a previous calendar month exists but its revenue is zero.

### Rules and constraints

- Use `dbo.Orders` as the source.
- Include orders dated from January 1, 2026, through December 31, 2026.
- Aggregate revenue at the calendar-month level.
- Use a window function to retrieve the previous month's revenue.
- Handle missing months correctly: the previous month means the previous calendar month, not merely the previous row returned by the aggregation.
- Use `NULLIF` to prevent division by zero.
- Sort by `RevenueMonth` ascending.
- Do not use hardcoded monthly revenue values.

### Expected output structure

| RevenueMonth | MonthlyRevenue | PreviousMonthRevenue | RevenueChange | RevenueGrowthPct | RevenueTrend |
| ------------ | -------------- | -------------------- | ------------- | ---------------- | ------------ |
| 2026-01-01   | Calculated     | NULL                 | NULL          | NULL             | First Month  |
| 2026-02-01   | Calculated     | Calculated           | Calculated    | Calculated       | Calculated   |
| …            | …              | …                    | …             | …                | …            |

These are illustrative rows, not actual database results.

### Your task

Create the file:

`06_Data_Engineering/task-061-monthly-revenue-trend-growth-analysis.sql`

Start by writing the query yourself. I will not provide hints or a solution before your first attempt. Paste your SQL here when you're ready, and I'll review it against the business requirements.