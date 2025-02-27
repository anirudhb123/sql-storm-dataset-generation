
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 1 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_customer_sk = ch.c_customer_sk
    WHERE ch.level < 3
),
sales_summary AS (
    SELECT ws.ws_bill_customer_sk AS customer_sk,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_sales_price) AS total_sales,
           COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
return_summary AS (
    SELECT sr.sr_customer_sk AS customer_sk,
           SUM(sr.sr_return_quantity) AS total_returns,
           SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk
),
full_summary AS (
    SELECT cs.c_customer_sk,
           COALESCE(ss.total_quantity, 0) AS total_quantity,
           COALESCE(ss.total_sales, 0) AS total_sales,
           COALESCE(rs.total_returns, 0) AS total_returns,
           COALESCE(rs.total_return_amount, 0) AS total_return_amount,
           CASE 
               WHEN COALESCE(ss.total_sales, 0) > 0 THEN 
                   (COALESCE(ss.total_sales, 0) - COALESCE(rs.total_return_amount, 0)) / COALESCE(ss.total_sales, 1)
               ELSE 0 
           END AS net_sales_ratio
    FROM customer cs
    LEFT JOIN sales_summary ss ON cs.c_customer_sk = ss.customer_sk
    LEFT JOIN return_summary rs ON cs.c_customer_sk = rs.customer_sk
)
SELECT ch.c_first_name,
       ch.c_last_name,
       fs.total_quantity,
       fs.total_sales,
       fs.total_returns,
       fs.total_return_amount,
       fs.net_sales_ratio,
       CASE 
           WHEN fs.net_sales_ratio < 0.2 THEN 'Low Profitability'
           WHEN fs.net_sales_ratio >= 0.2 AND fs.net_sales_ratio < 0.5 THEN 'Medium Profitability'
           ELSE 'High Profitability'
       END AS profitability_category
FROM customer_hierarchy ch
JOIN full_summary fs ON ch.c_customer_sk = fs.c_customer_sk
ORDER BY ch.level, fs.total_sales DESC
LIMIT 100;
