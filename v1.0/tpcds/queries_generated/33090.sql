
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_year, 
           1 AS level, CAST(c_first_name AS VARCHAR(255)) AS hierarchy_path
    FROM customer
    WHERE c_birth_year IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_year,
           ch.level + 1, CONCAT(ch.hierarchy_path, ' -> ', c.c_first_name)
    FROM customer c
    JOIN customer_hierarchy ch ON ch.c_customer_sk = c.c_current_cdemo_sk
    WHERE c.c_birth_year IS NOT NULL
),
sales_summary AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_quantity) AS total_quantity, 
           SUM(ws_net_paid) AS total_net_paid
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
returns_summary AS (
    SELECT sr_customer_sk, 
           SUM(sr_return_quantity) AS total_returned_quantity, 
           SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM store_returns
    GROUP BY sr_customer_sk
),
combined_sales AS (
    SELECT cs.c_customer_sk,
           COALESCE(ss.total_quantity, 0) AS total_quantity_sold,
           COALESCE(ss.total_net_paid, 0) AS total_net_paid,
           COALESCE(rs.total_returned_quantity, 0) AS total_returned_quantity,
           COALESCE(rs.total_returned_amount, 0) AS total_returned_amount
    FROM customer cs
    LEFT JOIN sales_summary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN returns_summary rs ON cs.c_customer_sk = rs.sr_customer_sk
)
SELECT ch.hierarchy_path, 
       cs.total_quantity_sold, 
       cs.total_net_paid, 
       cs.total_returned_quantity, 
       cs.total_returned_amount,
       (cs.total_net_paid - cs.total_returned_amount) AS net_profit
FROM combined_sales cs
JOIN customer_hierarchy ch ON cs.c_customer_sk = ch.c_customer_sk
WHERE ch.level <= 3
ORDER BY net_profit DESC
LIMIT 10;
