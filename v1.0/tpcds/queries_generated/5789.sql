
WITH item_sales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_quantity), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_store_sales
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
),
sales_summary AS (
    SELECT 
        total_web_sales + total_catalog_sales + total_store_sales AS total_sales,
        CASE 
            WHEN (total_web_sales + total_catalog_sales + total_store_sales) = 0 THEN 0
            ELSE ROUND((total_web_sales * 1.0 / (total_web_sales + total_catalog_sales + total_store_sales)) * 100, 2)
        END AS web_sales_percentage,
        CASE 
            WHEN (total_web_sales + total_catalog_sales + total_store_sales) = 0 THEN 0
            ELSE ROUND((total_catalog_sales * 1.0 / (total_web_sales + total_catalog_sales + total_store_sales)) * 100, 2)
        END AS catalog_sales_percentage,
        CASE 
            WHEN (total_web_sales + total_catalog_sales + total_store_sales) = 0 THEN 0
            ELSE ROUND((total_store_sales * 1.0 / (total_web_sales + total_catalog_sales + total_store_sales)) * 100, 2)
        END AS store_sales_percentage
    FROM 
        item_sales
)
SELECT 
    SUM(total_sales) AS overall_total_sales,
    AVG(web_sales_percentage) AS avg_web_sales_percentage,
    AVG(catalog_sales_percentage) AS avg_catalog_sales_percentage,
    AVG(store_sales_percentage) AS avg_store_sales_percentage
FROM 
    sales_summary
WHERE 
    total_sales > 0
HAVING 
    overall_total_sales > 1000;
