
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS average_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459583 AND 2459589 -- Example date range
        AND i.i_brand = 'BrandX' -- Example brand filter
    GROUP BY ws.web_site_id
),
StoreData AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_net_profit) AS average_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_orders
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2459583 AND 2459589 -- Example date range
        AND i.i_brand = 'BrandX' -- Example brand filter
    GROUP BY s.s_store_id
),
CombinedSales AS (
    SELECT 
        'Web' AS channel,
        wd.web_site_id AS id,
        wd.total_quantity,
        wd.total_sales,
        wd.average_profit,
        wd.total_orders
    FROM SalesData wd
    UNION ALL
    SELECT 
        'Store' AS channel,
        sd.s_store_id AS id,
        sd.total_quantity,
        sd.total_sales,
        sd.average_profit,
        sd.total_orders
    FROM StoreData sd
)
SELECT 
    channel,
    id,
    total_quantity,
    total_sales,
    average_profit,
    total_orders,
    RANK() OVER (PARTITION BY channel ORDER BY total_sales DESC) AS sales_rank
FROM CombinedSales
ORDER BY channel, sales_rank;
