
WITH recent_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
),
inventory_summary AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory inv
    WHERE 
        inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(rs.total_quantity, 0) AS web_sales_quantity,
    COALESCE(is.total_quantity_on_hand, 0) AS inventory_quantity,
    (COALESCE(rs.total_net_paid, 0) - COALESCE(is.total_quantity_on_hand, 0) * i.i_current_price) AS profit_estimate
FROM 
    item i
LEFT JOIN 
    recent_sales rs ON i.i_item_sk = rs.ws_item_sk AND rs.rn = 1
LEFT JOIN 
    inventory_summary is ON i.i_item_sk = is.inv_item_sk
WHERE 
    i.i_current_price > 0 
    AND (COALESCE(rs.total_quantity, 0) > 10 OR COALESCE(is.total_quantity_on_hand, 0) < 5)
ORDER BY 
    profit_estimate DESC
LIMIT 100;
