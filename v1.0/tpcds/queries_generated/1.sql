
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
AggregatedSales AS (
    SELECT 
        i_item_id,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_sales,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        RankSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.rank <= 5
    GROUP BY 
        i.i_item_id
),
InventoryCheck AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        CASE 
            WHEN inv.inv_quantity_on_hand < 10 THEN 'Low Stock'
            WHEN inv.inv_quantity_on_hand BETWEEN 10 AND 50 THEN 'Normal Stock'
            ELSE 'High Stock'
        END AS stock_status
    FROM 
        inventory inv
)
SELECT 
    a.i_item_id,
    a.total_net_profit,
    a.total_sales,
    a.avg_sales_price,
    i.inv_quantity_on_hand,
    ic.stock_status
FROM 
    AggregatedSales a
LEFT JOIN 
    InventoryCheck ic ON a.i_item_sk = ic.inv_item_sk
JOIN 
    item i ON a.i_item_id = i.i_item_id
WHERE 
    a.total_net_profit > (SELECT AVG(total_net_profit) FROM AggregatedSales)
    AND i.i_brand = 'BrandX'
ORDER BY 
    a.total_net_profit DESC
LIMIT 100;
