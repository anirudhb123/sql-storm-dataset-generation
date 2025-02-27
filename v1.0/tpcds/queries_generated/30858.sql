
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk >= (
        SELECT MIN(d_date_sk) 
        FROM date_dim 
        WHERE d_year = 2023
    )
    GROUP BY ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        d.d_date_sk, 
        sd.ws_item_sk, 
        sd.total_quantity_sold + COALESCE(SUM(ws_quantity), 0),
        sd.total_sales + COALESCE(SUM(ws_sales_price), 0)
    FROM sales_data sd
    JOIN date_dim d ON d.d_date_sk = sd.ws_sold_date_sk + 1
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_item_sk = sd.ws_item_sk
    WHERE d.d_date_sk < (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_year = 2023
    )
    GROUP BY d.d_date_sk, sd.ws_item_sk, sd.total_quantity_sold, sd.total_sales
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.net_profit) AS customer_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM customer c
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id
),
top_items AS (
    SELECT 
        i.i_item_id,
        SUM(sd.total_quantity_sold) AS total_quantity_sold
    FROM sales_data sd
    JOIN item i ON i.i_item_sk = sd.ws_item_sk
    GROUP BY i.i_item_id
    ORDER BY total_quantity_sold DESC
    LIMIT 10
)
SELECT 
    ci.c_customer_id,
    ci.customer_net_profit,
    ti.i_item_id,
    ti.total_quantity_sold,
    ti2.total_quantity_sold AS previous_quantity_sold,
    CASE 
        WHEN ti.total_quantity_sold IS NULL THEN 'N/A'
        ELSE ROUND((ti.total_quantity_sold - COALESCE(ti2.total_quantity_sold, 0)) * 100.0 / COALESCE(ti2.total_quantity_sold, 1), 2) 
    END AS percentage_change
FROM customer_sales ci
CROSS JOIN top_items ti
LEFT JOIN top_items ti2 ON ti.i_item_id = ti2.i_item_id AND ti2.total_quantity_sold < ti.total_quantity_sold
WHERE ci.customer_net_profit > (
    SELECT AVG(customer_net_profit) 
    FROM customer_sales
)
ORDER BY ci.customer_net_profit DESC, ti.total_quantity_sold DESC;
