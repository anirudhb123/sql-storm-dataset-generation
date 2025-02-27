
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, 
           i_size, i_color, 1 AS level
    FROM item
    WHERE i_item_sk IN (SELECT DISTINCT sr_item_sk 
                        FROM store_returns 
                        WHERE sr_return_quantity > 0)

    UNION ALL

    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_current_price, 
           i.i_size, i.i_color, ih.level + 1
    FROM item_hierarchy ih
    JOIN item i ON i.i_item_sk = ih.i_item_sk
    WHERE ih.level < 5
),

customer_data AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           (SELECT MAX(sr_return_amt) 
            FROM store_returns sr 
            WHERE sr.sr_customer_sk = c.c_customer_sk) AS max_return_amt,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),

sales_summary AS (
    SELECT ws.ws_item_sk, 
           SUM(ws.ws_quantity) AS total_quantity_sold, 
           SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    WHERE ws.ws_sales_price > 0
    GROUP BY ws.ws_item_sk
),

final_summary AS (
    SELECT
        ch.i_item_id,
        ch.i_item_desc,
        ch.i_current_price,
        ch.i_size,
        ch.i_color,
        cs.total_quantity_sold,
        cs.total_net_profit,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.max_return_amt
    FROM item_hierarchy ch
    LEFT JOIN sales_summary cs ON ch.i_item_sk = cs.ws_item_sk
    FULL OUTER JOIN customer_data cd ON cd.rn = 1
    WHERE ch.level < 3 AND (cd.max_return_amt IS NOT NULL OR cd.cd_gender = 'M')
)

SELECT *
FROM final_summary
ORDER BY total_net_profit DESC NULLS LAST, i_item_desc;
