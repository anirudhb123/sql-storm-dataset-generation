
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number) AS cumulative_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number) AS sale_rank,
        COALESCE(sm.sm_ship_mode_id, 'NA') AS ship_mode
    FROM web_sales ws
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
), 
ItemSales AS (
    SELECT 
        ir.i_item_id,
        ir.i_item_desc,
        ir.i_current_price,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales_value,
        AVG(ir.i_current_price) AS avg_item_price,
        MAX(rs.cumulative_quantity) AS max_cumulative_quantity,
        MIN(rs.sale_rank) AS first_sale_rank
    FROM RankedSales rs
    JOIN item ir ON rs.ws_item_sk = ir.i_item_sk
    GROUP BY ir.i_item_id, ir.i_item_desc, ir.i_current_price
)

SELECT 
    isales.i_item_id,
    isales.i_item_desc,
    isales.total_sales_value,
    isales.avg_item_price,
    isales.max_cumulative_quantity,
    isales.first_sale_rank,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    CASE 
        WHEN isales.total_sales_value IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM ItemSales isales
JOIN web_sales ws ON isales.i_item_id = ws.ws_item_sk
GROUP BY isales.i_item_id, isales.i_item_desc, isales.total_sales_value, isales.avg_item_price, isales.max_cumulative_quantity, isales.first_sale_rank
HAVING isales.total_sales_value > 1000 OR isales.first_sale_rank <= 5
ORDER BY isales.total_sales_value DESC
LIMIT 50;
