
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rnk,
        SUM(ws_quantity) OVER (PARTITION BY ws_item_sk) AS total_quantity,
        AVG(ws_sales_price) OVER (PARTITION BY ws_item_sk) AS avg_sales_price
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
)
, HighPriceSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        total_quantity,
        avg_sales_price
    FROM 
        RankedSales
    WHERE 
        rnk = 1 
        AND ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales WHERE ws_sales_price IS NOT NULL)
)
SELECT 
    w.warehouse_name,
    COUNT(DISTINCT w.w_warehouse_sk) AS total_warehouses,
    COALESCE(SUM(hp.ws_sales_price * hp.total_quantity), 0) AS total_revenue,
    COUNT(DISTINCT CASE WHEN hp.total_quantity >= 100 THEN hp.ws_order_number END) AS high_volume_orders,
    MAX(hp.avg_sales_price) AS max_avg_price
FROM 
    HighPriceSales hp
LEFT JOIN 
    inventory i ON hp.ws_item_sk = i.inv_item_sk
FULL OUTER JOIN 
    warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
GROUP BY 
    w.warehouse_name
HAVING 
    MAX(hp.avg_sales_price) IS NOT NULL
ORDER BY 
    total_revenue DESC, total_warehouses DESC;
