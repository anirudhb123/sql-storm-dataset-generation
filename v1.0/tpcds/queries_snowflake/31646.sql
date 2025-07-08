WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_brand, i_current_price, 1 AS level
    FROM item
    WHERE i_current_price IS NOT NULL
    
    UNION ALL
    
    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_brand, i.i_current_price, ih.level + 1
    FROM item_hierarchy ih
    JOIN item i ON ih.i_item_sk = i.i_item_sk
    WHERE ih.level < 5  
), 
customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT ci.c_first_name, ci.c_last_name, ci.cd_gender, SUM(ws.ws_net_profit) AS total_profit
FROM customer_info ci
LEFT JOIN web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
JOIN item_hierarchy ih ON ws.ws_item_sk = ih.i_item_sk
WHERE ci.gender_rank <= 10
GROUP BY ci.c_first_name, ci.c_last_name, ci.cd_gender
HAVING SUM(ws.ws_net_profit) > (
    SELECT AVG(ws2.ws_net_profit)
    FROM web_sales ws2
    WHERE ws2.ws_ship_date_sk IN (
        SELECT d_date_sk FROM date_dim
        WHERE d_year = 2001 AND d_moy IN (6, 7)  
    )
)
ORDER BY total_profit DESC
LIMIT 20;