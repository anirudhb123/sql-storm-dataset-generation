
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_qty,
        SUM(ws.ws_sales_price) AS total_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year BETWEEN 2022 AND 2023
    GROUP BY ws.ws_item_sk, ws.ws_order_number, ws.ws_qty
),
high_value_sales AS (
    SELECT 
        ws_item_sk, 
        total_sales_price
    FROM ranked_sales
    WHERE sales_rank = 1
)
SELECT 
    ia.i_item_id,
    ia.i_item_desc,
    hvs.total_sales_price,
    COUNT(ws.ws_order_number) AS order_count
FROM high_value_sales hvs
JOIN item ia ON hvs.ws_item_sk = ia.i_item_sk
JOIN web_sales ws ON hvs.ws_order_number = ws.ws_order_number
GROUP BY ia.i_item_id, ia.i_item_desc, hvs.total_sales_price
ORDER BY hvs.total_sales_price DESC
LIMIT 10;
