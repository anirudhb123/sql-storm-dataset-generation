
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) as price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
SalesSummary AS (
    SELECT 
        ws.fs_item_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM 
        web_sales ws
    INNER JOIN 
        RankedSales rs ON ws.ws_item_sk = rs.ws_item_sk AND ws.ws_order_number = rs.ws_order_number
    WHERE 
        rs.price_rank = 1
    GROUP BY 
        ws.fs_item_sk
),
StoreInventory AS (
    SELECT 
        i.i_item_sk,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_stock
    FROM 
        inventory inv
    RIGHT JOIN 
        item i ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        i.i_item_sk
),
FinalSales AS (
    SELECT 
        ss.fs_item_sk,
        ss.total_profit,
        si.total_stock,
        CASE 
            WHEN si.total_stock = 0 THEN NULL 
            ELSE ss.total_profit / si.total_stock 
        END AS profit_per_stock
    FROM 
        SalesSummary ss
    LEFT JOIN 
        StoreInventory si ON ss.fs_item_sk = si.i_item_sk
)
SELECT 
    ws.web_site_id,
    f.fs_item_sk,
    f.total_profit,
    f.total_stock,
    f.profit_per_stock,
    d.d_date
FROM 
    FinalSales f
JOIN 
    date_dim d ON d.d_date_sk = f.fs_item_sk % (SELECT MAX(d_date_sk) FROM date_dim)  -- Obscure logic: mod operator for date dim
WHERE 
    f.profit_per_stock > (SELECT AVG(profit_per_stock) FROM FinalSales WHERE profit_per_stock IS NOT NULL)
ORDER BY 
    f.total_profit DESC
LIMIT 100
OFFSET (
    SELECT COUNT(DISTINCT cb.c_customer_sk) 
    FROM customer cb 
    WHERE 
        cb.c_birth_year IS NULL 
        OR (cb.c_birth_month = 2 AND cb.c_birth_day BETWEEN 29 AND 29)
)  -- Using a bizarre condition to set OFFSET based on customers with peculiar birth dates
```
