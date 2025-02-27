
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
item_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_current_price,
        COALESCE(ss.total_quantity, 0) AS total_quantity,
        COALESCE(ss.total_net_paid, 0) AS total_net_paid
    FROM 
        item i
    LEFT JOIN 
        sales_summary ss ON i.i_item_sk = ss.ws_item_sk
)
SELECT 
    is.item_id,
    is.total_quantity,
    is.total_net_paid,
    i.i_current_price,
    (is.total_net_paid / NULLIF(is.total_quantity, 0)) AS average_price_per_unit
FROM 
    item_summary is
JOIN 
    item i ON is.i_item_sk = i.i_item_sk
ORDER BY 
    average_price_per_unit DESC
LIMIT 100;
