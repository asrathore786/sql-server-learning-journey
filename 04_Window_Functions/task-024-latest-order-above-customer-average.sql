/*

Task 024 — Latest Order Above Customer Average
Business requirement
The sales team wants to identify customers whose most recent order amount is greater than their own average order amount.
Using your existing PracticeDatabase tables, Customers and Orders, write a SQL query that returns:
- CustomerID
- CustomerName
- LatestOrderDate
- LatestOrderAmount
- AverageOrderAmount
Rules
1. Calculate each customer's average order amount across all their orders.
2. Identify the most recent order date for each customer.
3. If a customer has multiple orders on that latest date, include all orders from that date.
4. Include all statuses: Completed, Pending, and Cancelled.
5. Return only the latest orders whose amount is strictly greater than the customer's average.
6. Sort the results by CustomerID.

*/


What we are finding here in --> need to check the most recent order f customer must be greater with the average of customer order amount,
We need to find out the average of Total amount per customers,
