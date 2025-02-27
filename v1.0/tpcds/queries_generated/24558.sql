
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL AND
        ws.ws_net_profit > 0
), InventoryCheck AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        CASE 
            WHEN inv.inv_quantity_on_hand > 100 THEN 'High Stock'
            WHEN inv.inv_quantity_on_hand BETWEEN 50 AND 100 THEN 'Medium Stock'
            ELSE 'Low Stock'
        END AS stock_level
    FROM 
        inventory inv
    WHERE 
        inv.inv_quantity_on_hand IS NOT NULL
), CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(DISTINCT cr.cr_order_number) AS return_count,
        SUM(cr.cr_return_amt) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
), AggregatedSales AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sales_price IS NOT NULL
    GROUP BY 
        cs.cs_item_sk
)
SELECT 
    i.inv_item_sk,
    COALESCE(rs.ws_sales_price, 0) AS web_price,
    COALESCE(a.total_sales, 0) AS catalog_sales,
    COALESCE(cr.return_count, 0) AS returns,
    COALESCE(cr.total_return_amount, 0) AS total_returns_value,
    i.stock_level
FROM 
    InventoryCheck i
LEFT JOIN 
    RankedSales rs ON i.inv_item_sk = rs.ws_item_sk AND rs.rnk = 1
FULL OUTER JOIN 
    AggregatedSales a ON i.inv_item_sk = a.cs_item_sk
LEFT JOIN 
    CustomerReturns cr ON i.inv_item_sk = cr.cr_item_sk
WHERE 
    i.stock_level = 'Low Stock' OR 
    (COALESCE(a.total_sales, 0) > 1000 AND COALESCE(cr.return_count, 0) = 0)
ORDER BY 
    i.inv_item_sk;
