
WITH RECURSIVE sales_hierarchy AS (
    SELECT sm_ship_mode_sk, sm_type, sm_code, 1 AS level
    FROM ship_mode
    WHERE sm_type IS NOT NULL
    
    UNION ALL
    
    SELECT sm.sm_ship_mode_sk, sm.sm_type, sm.sm_code, sh.level + 1
    FROM sales_hierarchy sh
    JOIN ship_mode sm ON sh.sm_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm_type LIKE '%Express%'
),
customer_info AS (
    SELECT c.c_customer_id, c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1995 AND cd.cd_purchase_estimate > 1000
),
item_sales AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023 AND d_moy IN (1, 2, 3)
    )
    GROUP BY ws.ws_item_sk
)
SELECT ci.c_customer_id, ci.cd_gender, ci.cd_marital_status,
       COUNT(DISTINCT is.item_sk) AS total_items,
       SUM(iss.total_sales) AS total_revenue,
       CASE 
           WHEN ci.cd_marital_status = 'M' THEN 'Married'
           ELSE 'Single'
       END AS marital_status_group,
       MAX(sh.level) AS max_ship_mode_level
FROM customer_info ci
LEFT JOIN item_sales iss ON iss.ws_item_sk IN (
    SELECT DISTINCT cs_item_sk
    FROM catalog_sales
    WHERE cs_sold_date_sk = (
        SELECT MAX(cs_sold_date_sk)
        FROM catalog_sales
        WHERE cs_order_number IN (
            SELECT sr_ticket_number
            FROM store_returns
            WHERE sr_return_quantity > 0
        )
    )
)
JOIN sales_hierarchy sh ON ci.c_current_cdemo_sk = sh.sm_ship_mode_sk
GROUP BY ci.c_customer_id, ci.cd_gender, ci.cd_marital_status
HAVING total_revenue > 5000
ORDER BY total_revenue DESC;

