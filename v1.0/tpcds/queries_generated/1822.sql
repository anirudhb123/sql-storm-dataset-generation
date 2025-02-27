
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM web_sales ws
),
ItemSales AS (
    SELECT 
        inv.inv_item_sk,
        SUM(ss.ss_net_profit) AS total_store_sales,
        SUM(ws.ws_net_profit) AS total_web_sales,
        COALESCE(SUM(ss.ss_net_profit), 0) + COALESCE(SUM(ws.ws_net_profit), 0) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_tickets
    FROM inventory inv
    LEFT JOIN store_sales ss ON inv.inv_item_sk = ss.ss_item_sk
    LEFT JOIN web_sales ws ON inv.inv_item_sk = ws.ws_item_sk
    GROUP BY inv.inv_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.total_store_sales, 0) AS total_store_sales,
    COALESCE(s.total_web_sales, 0) AS total_web_sales,
    CASE 
        WHEN COALESCE(s.total_sales, 0) > 0 
        THEN ROUND((COALESCE(s.total_store_sales, 0) / COALESCE(s.total_sales, 0)) * 100, 2)
        ELSE 0
    END AS store_sales_percentage,
    CASE 
        WHEN COALESCE(s.total_sales, 0) > 0 
        THEN ROUND((COALESCE(s.total_web_sales, 0) / COALESCE(s.total_sales, 0)) * 100, 2)
        ELSE 0
    END AS web_sales_percentage,
    (SELECT MAX(ws_sales_price) 
     FROM RankedSales 
     WHERE ws_item_sk = i.i_item_sk AND rn = 1) AS latest_web_price
FROM item i
LEFT JOIN ItemSales s ON i.i_item_sk = s.inv_item_sk
WHERE i.i_current_price > 0
ORDER BY total_sales DESC
LIMIT 100;
