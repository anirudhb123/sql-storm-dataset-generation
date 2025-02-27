
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           cd.cd_gender, cd.cd_marital_status, 1 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender IS NOT NULL

    UNION ALL

    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.c_current_cdemo_sk,
           cd2.cd_gender, cd2.cd_marital_status, level + 1
    FROM customer_hierarchy ch
    JOIN customer c2 ON ch.c_customer_sk = c2.c_current_cdemo_sk
    JOIN customer_demographics cd2 ON c2.c_current_cdemo_sk = cd2.cd_demo_sk
    WHERE cd2.cd_gender IS NOT NULL AND ch.level < 3
),
sales_data AS (
    SELECT ws.ws_bill_customer_sk, SUM(ws.ws_net_profit) AS total_net_profit,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           AVG(ws.ws_net_paid) AS avg_net_paid
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500
    GROUP BY ws.ws_bill_customer_sk
),
funnel_data AS (
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name,
           COALESCE(sd.total_net_profit, 0) AS total_net_profit,
           COALESCE(sd.total_orders, 0) AS total_orders,
           CASE WHEN sd.avg_net_paid IS NOT NULL THEN sd.avg_net_paid ELSE 0 END AS avg_net_paid
    FROM customer_hierarchy ch
    LEFT JOIN sales_data sd ON ch.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT f.c_customer_sk, f.c_first_name, f.c_last_name,
       f.total_net_profit, f.total_orders, f.avg_net_paid,
       CASE 
           WHEN f.total_orders > 10 AND f.avg_net_paid > 50 THEN 'High Value'
           WHEN f.total_orders BETWEEN 5 AND 10 AND f.avg_net_paid BETWEEN 30 AND 50 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_value,
       CONCAT(f.c_first_name, ' ', f.c_last_name) AS full_name,
       ROW_NUMBER() OVER (PARTITION BY f.total_net_profit ORDER BY f.avg_net_paid DESC) AS rank
FROM funnel_data f
WHERE f.total_net_profit IS NOT NULL OR f.total_orders IS NOT NULL
ORDER BY f.total_net_profit DESC, f.avg_net_paid DESC;
