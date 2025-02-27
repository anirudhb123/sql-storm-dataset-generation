
WITH SalesData AS (
    SELECT 
        s_store_sk,
        SUM(CASE WHEN ws_sold_date_sk IS NOT NULL THEN ws_sales_price ELSE 0 END) AS total_web_sales,
        SUM(CASE WHEN cs_sold_date_sk IS NOT NULL THEN cs_sales_price ELSE 0 END) AS total_catalog_sales,
        SUM(CASE WHEN ss_sold_date_sk IS NOT NULL THEN ss_sales_price ELSE 0 END) AS total_store_sales,
        COUNT(DISTINCT ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs_order_number) AS total_catalog_orders,
        COUNT(DISTINCT ss_ticket_number) AS total_store_orders
    FROM web_sales
    FULL OUTER JOIN catalog_sales ON ws_item_sk = cs_item_sk AND ws_sold_date_sk = cs_sold_date_sk
    FULL OUTER JOIN store_sales ON ws_item_sk = ss_item_sk AND ws_sold_date_sk = ss_sold_date_sk
    GROUP BY s_store_sk
),
SalesOverview AS (
    SELECT
        s.s_store_name,
        s.s_city,
        s.s_state,
        sd.total_web_sales,
        sd.total_catalog_sales,
        sd.total_store_sales,
        sd.total_web_orders,
        sd.total_catalog_orders,
        sd.total_store_orders,
        (sd.total_web_sales + sd.total_catalog_sales + sd.total_store_sales) AS total_sales,
        (sd.total_web_orders + sd.total_catalog_orders + sd.total_store_orders) AS total_orders
    FROM store s
    JOIN SalesData sd ON s.s_store_sk = sd.s_store_sk
)
SELECT 
    so.s_store_name,
    so.s_city,
    so.s_state,
    so.total_sales,
    so.total_orders,
    (so.total_sales / NULLIF(so.total_orders, 0)) AS average_sales_per_order,
    RANK() OVER (ORDER BY so.total_sales DESC) AS sales_rank
FROM SalesOverview so
WHERE so.total_sales > 0
ORDER BY so.total_sales DESC
LIMIT 10;
