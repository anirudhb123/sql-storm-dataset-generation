
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws.warehouse_sk,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.warehouse_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS rnk
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.warehouse_sk
    GROUP BY 
        ws.warehouse_sk, ws.ws_item_sk
    HAVING 
        SUM(ws.ws_sales_price * ws.ws_quantity) > (
            SELECT AVG(total_sales)
            FROM (
                SELECT SUM(ws2.ws_sales_price * ws2.ws_quantity) AS total_sales
                FROM web_sales ws2
                GROUP BY ws2.ws_item_sk
            ) as avg_sales
        )
),
inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        COALESCE(i.i_current_price, 0) AS current_price
    FROM 
        inventory inv
    LEFT JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
),
ranked_returns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        ROW_NUMBER() OVER (PARTITION BY cr.cr_item_sk ORDER BY SUM(cr.cr_return_quantity) DESC) AS rnk
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    i.inv_item_sk,
    i.inv_quantity_on_hand,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    CASE 
        WHEN i.inv_quantity_on_hand = 0 THEN 'Out of Stock' 
        ELSE 'In Stock' 
    END AS stock_status,
    (i.inv_quantity_on_hand * i.current_price) - COALESCE(r.total_returns * i.current_price, 0) AS net_value
FROM 
    inventory_data i
LEFT JOIN 
    sales_cte s ON i.inv_item_sk = s.ws_item_sk
LEFT JOIN 
    ranked_returns r ON i.inv_item_sk = r.cr_item_sk AND r.rnk = 1
WHERE 
    (s.total_sales IS NULL OR r.total_returns IS NULL) 
    AND (i.inv_quantity_on_hand IS NOT NULL OR i.current_price != 0)
ORDER BY 
    net_value DESC
LIMIT 100;
