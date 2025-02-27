
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, 
           0 AS level
    FROM item
    WHERE i_current_price > 100.00
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_current_price, 
           ih.level + 1
    FROM item_hierarchy ih
    JOIN item i ON ih.i_item_sk = i.i_item_sk
    WHERE i.i_current_price < 100.00 AND ih.level < 5
),
customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status,
           COALESCE(ROUND(SUM(ss.ss_net_profit), 2), 0) AS total_net_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
sales_summary AS (
    SELECT ws.ws_ship_mode_sk, sm.sm_type, SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY ws.ws_ship_mode_sk, sm.sm_type
)
SELECT ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status,
       ih.i_item_desc, ih.i_current_price,
       ss.total_net_profit,
       CASE WHEN ss.total_net_profit > 500 THEN 'High Value'
            WHEN ss.total_net_profit BETWEEN 100 AND 500 THEN 'Medium Value'
            ELSE 'Low Value' END AS customer_value,
       CASE WHEN ih.level = 0 THEN 'Tier 1'
            WHEN ih.level = 1 THEN 'Tier 2'
            WHEN ih.level = 2 THEN 'Tier 3'
            WHEN ih.level < 5 THEN 'Tier 4'
            ELSE 'Tier 5' END AS item_tier
FROM customer_info ci
JOIN item_hierarchy ih ON ci.c_customer_sk = (SELECT MIN(ws_bill_customer_sk)
                                               FROM web_sales
                                               WHERE ws_ship_mode_sk IN (SELECT ss.ws_ship_mode_sk
                                                                         FROM sales_summary ss 
                                                                         WHERE ss.total_net_profit > 0)
                                               LIMIT 1)
LEFT JOIN sales_summary ss ON ss.ws_ship_mode_sk IS NOT NULL
WHERE ci.total_net_profit >= (SELECT AVG(total_net_profit) FROM customer_info)
ORDER BY ci.c_last_name ASC, ih.i_current_price DESC;
