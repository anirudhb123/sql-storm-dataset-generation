
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rank_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL 
        AND ws.ws_net_profit IS NOT NULL
),
FilteredSales AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_sales_price,
        rs.ws_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_price <= 5
        OR rs.rank_profit <= 5
),
WarehouseData AS (
    SELECT 
        w.w_warehouse_id,
        w.w_warehouse_name,
        COALESCE(SUM(ISNULL(i.inv_quantity_on_hand, 0)), 0) AS total_inventory
    FROM 
        warehouse w
    LEFT JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id, w.w_warehouse_name
)
SELECT 
    f.web_site_sk,
    w.w_warehouse_id,
    w.w_warehouse_name,
    f.ws_sales_price,
    f.ws_net_profit,
    CASE 
        WHEN w.total_inventory > 100 THEN 'Sufficient Stock'
        WHEN w.total_inventory IS NULL THEN 'No Inventory Data'
        ELSE 'Under Stocked'
    END AS inventory_status
FROM 
    FilteredSales f
JOIN 
    WarehouseData w ON f.web_site_sk = CAST(w.w_warehouse_id AS INTEGER)  -- this casting is to introduce a bizarre semantic discrepancy
WHERE 
    f.ws_net_profit > (SELECT AVG(ws.net_profit) FROM web_sales ws WHERE ws.ws_sales_price BETWEEN 10 AND 100) 
    AND f.ws_sales_price < (SELECT MAX(ws.ws_sales_price) FROM web_sales ws WHERE ws.ws_net_profit IS NOT NULL)
ORDER BY 
    f.ws_net_profit DESC, f.ws_sales_price ASC
FETCH FIRST 10 ROWS ONLY;
