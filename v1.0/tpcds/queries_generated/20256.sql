
WITH RECURSIVE date_series AS (
    SELECT MIN(d_date) AS date_value 
    FROM date_dim 
    UNION ALL 
    SELECT DATE_ADD(date_value, INTERVAL 1 DAY) 
    FROM date_series 
    WHERE date_value < (SELECT MAX(d_date) FROM date_dim)
), 
item_inventory AS (
    SELECT 
        i.i_item_sk, i.i_item_id, 
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory
    FROM item i
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
), 
sales_data AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rnk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) AND CURRENT_DATE()
    GROUP BY ws.ws_item_sk
), 
aggregated_sales AS (
    SELECT 
        i.i_item_id, 
        COALESCE(sd.total_sales, 0) AS total_sales, 
        COALESCE(sd.total_profit, 0) AS total_profit, 
        COALESCE(i.total_inventory, 0) AS total_inventory,
        ROUND((COALESCE(sd.total_profit, 0) / NULLIF(COALESCE(i.total_inventory, 0), 0)) * 100, 2) AS profit_margin,
        CASE 
            WHEN COALESCE(sd.total_sales, 0) = 0 THEN 'No Sales'
            WHEN COALESCE(i.total_inventory, 0) = 0 THEN 'Out of Stock'
            ELSE 'Available'
        END AS availability_status
    FROM item_inventory i
    LEFT JOIN sales_data sd ON i.i_item_sk = sd.ws_item_sk
)
SELECT 
    g.availability_status, 
    g.i_item_id, 
    g.total_sales, 
    g.total_profit, 
    g.total_inventory, 
    g.profit_margin
FROM aggregated_sales g
WHERE g.profit_margin > 0
AND g.availability_status = 'Available'
ORDER BY g.total_profit DESC
LIMIT 20;
