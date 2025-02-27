
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_paid,
        cs.cs_sales_price AS catalog_sales_price,
        ss.ss_sales_price AS store_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_paid DESC) as row_num
    FROM 
        web_sales ws
    LEFT JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    LEFT JOIN 
        store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
RankedSales AS (
    SELECT 
        *,
        COALESCE(catalog_sales_price, 0) AS effective_catalog_price,
        COALESCE(store_sales_price, 0) AS effective_store_price
    FROM 
        SalesData
)
SELECT 
    r.ws_order_number,
    r.ws_item_sk,
    r.ws_sales_price,
    r.ws_quantity,
    r.ws_net_paid,
    r.effective_catalog_price,
    r.effective_store_price
FROM 
    RankedSales r
WHERE 
    r.row_num = 1
    AND (r.ws_net_paid > 100 OR r.effective_catalog_price > r.effective_store_price)
ORDER BY 
    r.ws_net_paid DESC
LIMIT 100
UNION ALL
SELECT 
    NULL AS ws_order_number,
    cs.cs_item_sk,
    NULL AS ws_sales_price,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(cs.cs_net_paid) AS total_net_paid,
    NULL AS effective_catalog_price,
    NULL AS effective_store_price
FROM 
    catalog_sales cs
WHERE 
    cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
GROUP BY 
    cs.cs_item_sk
HAVING 
    SUM(cs.cs_net_paid) > 200
ORDER BY 
    total_net_paid DESC;
