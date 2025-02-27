
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, 
           cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating,
           1 AS level
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, 
           CASE WHEN cd.cd_purchase_estimate IS NULL THEN 0 ELSE cd.cd_purchase_estimate END, 
           cd.cd_credit_rating, 
           ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_current_cdemo_sk = ch.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ch.level < 3
),
total_sales AS (
    SELECT ws_bill_customer_sk, SUM(ws_net_profit) AS total_net_profit,
           COUNT(ws_order_number) AS total_orders,
           ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
top_customers AS (
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, 
           ch.cd_gender, ch.cd_marital_status, 
           COALESCE(ts.total_net_profit, 0) AS total_net_profit,
           COALESCE(ts.total_orders, 0) AS total_orders
    FROM customer_hierarchy ch
    LEFT JOIN total_sales ts ON ch.c_customer_sk = ts.ws_bill_customer_sk
    WHERE ch.level = 1
)
SELECT tc.c_first_name, tc.c_last_name, tc.cd_gender, 
       CASE WHEN tc.total_net_profit IS NULL THEN 'No Sales' 
            WHEN tc.total_net_profit BETWEEN 1 AND 100 THEN 'Low Sales'
            WHEN tc.total_net_profit BETWEEN 101 AND 1000 THEN 'Medium Sales' 
            ELSE 'High Sales' END AS sales_category,
       MAX(sa.total_quantity) AS max_quantity,
       COUNT(DISTINCT ws.ws_order_number) AS web_order_count
FROM top_customers tc
LEFT JOIN web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN (
    SELECT ws_bill_customer_sk, SUM(ws_quantity) AS total_quantity
    FROM web_sales
    GROUP BY ws_bill_customer_sk
    HAVING SUM(ws_quantity) > 5
) sa ON tc.c_customer_sk = sa.ws_bill_customer_sk
GROUP BY tc.c_first_name, tc.c_last_name, tc.cd_gender, 
         tc.total_net_profit
ORDER BY sales_category DESC, tc.c_last_name ASC;
