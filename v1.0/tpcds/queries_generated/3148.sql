
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws_net_profit, 
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
),
TopProfitableSites AS (
    SELECT 
        web_site_sk, 
        SUM(ws_net_profit) AS total_profit
    FROM 
        RankedSales
    WHERE 
        rank_profit <= 5
    GROUP BY 
        web_site_sk
),
InventoryStatus AS (
    SELECT 
        inv.inv_warehouse_sk, 
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_warehouse_sk
)
SELECT 
    w.warehouse_name,
    COALESCE(ts.total_profit, 0) AS total_profit,
    COALESCE(is.total_quantity, 0) AS total_quantity,
    (COALESCE(ts.total_profit, 0) + COALESCE(is.total_quantity, 0)) AS combined_metric
FROM 
    warehouse w
LEFT JOIN 
    TopProfitableSites ts ON w.w_warehouse_sk = ts.web_site_sk
LEFT JOIN 
    InventoryStatus is ON w.w_warehouse_sk = is.inv_warehouse_sk
WHERE 
    (ts.total_profit IS NOT NULL OR is.total_quantity IS NOT NULL) 
    AND (w.w_warehouse_name LIKE '%Store%' OR w.w_warehouse_name LIKE 'Main%')
ORDER BY 
    combined_metric DESC
LIMIT 10;

