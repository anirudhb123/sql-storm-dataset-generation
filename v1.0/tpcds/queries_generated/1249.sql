
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rank,
        cs.cs_sales_price,
        cs.cs_quantity,
        sm.sm_type,
        CASE 
            WHEN ws.ws_sales_price > cs.cs_sales_price THEN 'Web'
            ELSE 'Catalog'
        END AS Sales_Channel
    FROM web_sales ws
    JOIN catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_sold_date_sk = cs.cs_sold_date_sk AND ws.ws_ship_mode_sk IS NOT NULL
),
AggregatedSales AS (
    SELECT 
        web_site_sk,
        Sales_Channel,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(*) AS sales_count
    FROM RankedSales
    WHERE rank <= 5
    GROUP BY web_site_sk, Sales_Channel
)
SELECT 
    w.w_warehouse_name,
    AS.sales_Channel,
    total_sales,
    sales_count,
    COALESCE(max(ws_quantity), 0) AS max_quantity_sold,
    NULLIF(AVG(CASE WHEN sales_count > 0 THEN total_sales / sales_count END), 0) AS avg_sales_per_order
FROM AggregatedSales AS AS
LEFT JOIN warehouse w ON w.w_warehouse_sk = AS.web_site_sk
GROUP BY w.w_warehouse_name, AS.sales_Channel, total_sales, sales_count
ORDER BY total_sales DESC
LIMIT 10;
