
WITH RECURSIVE Customer_CTE AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           d.d_date AS first_order_date,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d.d_date) as order_num
    FROM customer c
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
),
Recent_Returns AS (
    SELECT sr.returned_date_sk,
           SUM(sr.return_quantity) AS total_returned,
           SUM(sr.return_amt) AS total_return_amt,
           SUM(sr.return_tax) AS total_return_tax
    FROM store_returns sr
    GROUP BY sr.returned_date_sk
),
Sales_Stats AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_sales_price) AS total_sales,
           COUNT(ws_order_number) AS order_count,
           AVG(ws_net_profit) AS avg_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY ws_bill_customer_sk
)
SELECT c.c_customer_sk,
       c.c_first_name,
       c.c_last_name,
       cs.total_sales,
       cs.order_count,
       coalesce(rr.total_returned, 0) AS total_returned,
       coalesce(rr.total_return_amt, 0) AS total_return_amt,
       CASE 
           WHEN cs.avg_profit IS NULL THEN 'No Sales'
           WHEN cs.avg_profit > 100 THEN 'High Profit'
           ELSE 'Low Profit'
       END AS profit_category
FROM Customer_CTE c
LEFT JOIN Sales_Stats cs ON c.c_customer_sk = cs.ws_bill_customer_sk
LEFT JOIN Recent_Returns rr ON rr.returned_date_sk = c.first_order_date
WHERE c.order_num = 1
  AND (c.c_last_name LIKE 'S%' OR c.c_first_name LIKE 'A%')
ORDER BY cs.total_sales DESC NULLS LAST;
