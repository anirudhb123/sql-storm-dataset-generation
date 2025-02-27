
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_last_name IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE c.c_last_name IS NOT NULL AND ch.level < 3
),
sales_summary AS (
    SELECT
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    INNER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.web_site_sk
),
top_sales AS (
    SELECT web_site_sk, total_profit, total_orders,
           RANK() OVER (ORDER BY total_profit DESC) AS rank_profit,
           ROW_NUMBER() OVER (ORDER BY total_orders DESC) AS row_num_orders
    FROM sales_summary
    WHERE total_profit IS NOT NULL
),
customer_details AS (
    SELECT ch.c_customer_sk, 
           CONCAT(ch.c_first_name, ' ', ch.c_last_name) AS full_name,
           cd.cd_gender, 
           cd.cd_marital_status,
           COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate
    FROM customer_hierarchy ch
    LEFT JOIN customer_demographics cd ON ch.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT c.full_name,
       CASE 
           WHEN c.cd_gender = 'M' THEN 'Mr. ' || c.full_name
           ELSE 'Ms. ' || c.full_name 
       END AS formatted_name,
       ss.total_profit,
       ss.total_orders,
       ss.web_site_sk,
       CASE 
           WHEN ss.total_orders > 10 THEN 0.1 * ss.total_profit 
           ELSE NULL 
       END AS bonus,
       COALESCE(th.rank_profit, 0) AS sales_rank,
       COALESCE(th.row_num_orders, 0) AS orders_rank
FROM customer_details c
LEFT JOIN top_sales th ON c.c_customer_sk = th.web_site_sk
LEFT JOIN sales_summary ss ON th.web_site_sk = ss.web_site_sk
WHERE c.purchase_estimate IS NOT NULL
AND ss.total_profit IS NOT NULL
ORDER BY c.full_name ASC, ss.total_profit DESC
LIMIT 100;
