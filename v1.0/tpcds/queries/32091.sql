
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           cd.cd_dep_count, 1 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 10000

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           cd.cd_dep_count, level + 1
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_hierarchy ch ON c.c_customer_sk = ch.c_customer_sk
    WHERE ch.level < 3
)

SELECT 
    ch.c_customer_sk,
    CONCAT(ch.c_first_name, ' ', ch.c_last_name) AS full_name,
    ch.cd_gender,
    ch.cd_marital_status,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    (CASE 
        WHEN SUM(ws.ws_net_profit) IS NULL THEN 0 
        ELSE SUM(ws.ws_net_profit) / NULLIF(COUNT(DISTINCT ws.ws_order_number), 0)
    END) AS avg_profit_per_order
FROM customer_hierarchy ch
LEFT JOIN web_sales ws ON ch.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.cd_gender, ch.cd_marital_status
ORDER BY total_net_profit DESC
LIMIT 10;
