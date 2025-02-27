
WITH recursive customer_rank AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year IS NOT NULL
),
item_sales AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk = (
        SELECT MAX(d_date_sk)
        FROM date_dim
        WHERE d_date >= NOW() - INTERVAL '1 month'
    )
    GROUP BY ws.ws_item_sk
),
high_sales_items AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_product_name,
           is.total_quantity,
           is.total_profit,
           (CASE
                WHEN is.total_profit IS NULL THEN 'Not Available'
                WHEN is.total_profit > 1000 THEN 'High Earner'
                ELSE 'Low Earner'
            END) AS performance_category
    FROM item i
    LEFT JOIN item_sales is ON i.i_item_sk = is.ws_item_sk
)
SELECT cr.c_customer_sk,
       cr.c_first_name,
       cr.c_last_name,
       COALESCE(hsi.i_item_id, 'No Purchases') AS item_id,
       hsi.performance_category,
       COUNT(DISTINCT cs.cs_order_number) AS total_orders,
       SUM(cs.cs_sales_price) AS total_sales
FROM customer_rank cr
LEFT JOIN catalog_sales cs ON cs.cs_ship_customer_sk = cr.c_customer_sk
LEFT JOIN high_sales_items hsi ON hsi.i_item_sk = cs.cs_item_sk
WHERE cr.rank <= 10 
AND (hsi.total_quantity IS NULL OR hsi.total_quantity > 5)
GROUP BY cr.c_customer_sk, cr.c_first_name, cr.c_last_name, hsi.i_item_id, hsi.performance_category
HAVING SUM(cs.cs_sales_price) IS NOT NULL 
   OR COUNT(cs.cs_order_number) > 1
ORDER BY cr.c_last_name ASC, cr.c_first_name ASC;
