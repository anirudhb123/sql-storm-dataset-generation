
WITH RecursiveSales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023) 
    GROUP BY 
        ws.ws_item_sk
), ItemStats AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_id, 
        COALESCE(SUM(cs.cs_quantity), 0) AS catalog_sales_quantity,
        COALESCE(MIN(sm.sm_ship_mode_id), 'None') AS min_ship_mode,
        COALESCE(MAX(sm.sm_ship_mode_id), 'None') AS max_ship_mode
    FROM 
        item i
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk 
    LEFT JOIN 
        ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
), ComprehensiveStats AS (
    SELECT
        ir.ws_item_sk,
        ir.total_quantity,
        ir.total_profit,
        is.catalog_sales_quantity,
        is.min_ship_mode,
        is.max_ship_mode
    FROM 
        RecursiveSales ir
    JOIN 
        ItemStats is ON ir.ws_item_sk = is.i_item_sk
    WHERE 
        ir.rn = 1
)
SELECT 
    cs.ws_item_sk,
    cs.total_quantity,
    cs.total_profit,
    cs.catalog_sales_quantity,
    CASE
        WHEN cs.catalog_sales_quantity > 100 THEN 'High Performer'
        WHEN cs.catalog_sales_quantity BETWEEN 50 AND 100 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category,
    (SELECT COUNT(DISTINCT wr_refunded_customer_sk) FROM web_returns wr WHERE wr.wr_item_sk = cs.ws_item_sk) AS return_count,
    (SELECT AVG(greatest(ws_net_profit, 0)) 
     FROM (
         SELECT DISTINCT ws_net_profit FROM web_sales 
         WHERE ws_item_sk = cs.ws_item_sk AND ws_net_profit IS NOT NULL
     ) AS net_profit_data) AS average_profit
FROM 
    ComprehensiveStats cs
WHERE 
    cs.total_profit IS NOT NULL
ORDER BY 
    cs.total_profit DESC, 
    performance_category DESC
LIMIT 50;
