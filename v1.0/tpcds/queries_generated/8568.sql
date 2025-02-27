
WITH SalesData AS (
    SELECT 
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        cs.cs_quantity,
        cs.cs_sales_price,
        ss.ss_quantity,
        ss.ss_sales_price
    FROM 
        web_sales ws
    LEFT JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk AND ws.ws_sold_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        store_sales ss ON ws.ws_item_sk = ss.ss_item_sk AND ws.ws_sold_date_sk = ss.ss_sold_date_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
),
AggregatedSales AS (
    SELECT 
        sd.ws_web_site_sk,
        SUM(sd.ws_quantity) AS total_web_quantity,
        SUM(sd.ws_ext_sales_price) AS total_web_sales,
        SUM(sd.cs_quantity) AS total_catalog_quantity,
        SUM(sd.cs_sales_price) AS total_catalog_sales,
        SUM(sd.ss_quantity) AS total_store_quantity,
        SUM(sd.ss_sales_price) AS total_store_sales
    FROM 
        SalesData sd
    GROUP BY 
        sd.ws_web_site_sk
)
SELECT 
    w.warehouse_id AS Warehouse_ID,
    ag.total_web_quantity,
    ag.total_web_sales,
    ag.total_catalog_quantity,
    ag.total_catalog_sales,
    ag.total_store_quantity,
    ag.total_store_sales
FROM 
    AggregatedSales ag
JOIN 
    warehouse w ON w.w_warehouse_sk = ag.ws_web_site_sk
WHERE 
    ag.total_web_sales > (SELECT AVG(total_web_sales) FROM AggregatedSales)
ORDER BY 
    ag.total_web_sales DESC
LIMIT 10;
