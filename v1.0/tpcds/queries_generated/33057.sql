
WITH RECURSIVE item_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_quantity) DESC) AS rn
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
ranked_sales AS (
    SELECT 
        is.ws_item_sk,
        COALESCE(is.total_sales, 0) AS web_sales_total,
        COALESCE(cs.total_sales, 0) AS catalog_sales_total,
        COALESCE(is.total_sales, 0) + COALESCE(cs.total_sales, 0) AS combined_sales
    FROM 
        item_sales is
    FULL OUTER JOIN (
        SELECT 
            cs_item_sk,
            SUM(cs_quantity) AS total_sales
        FROM 
            catalog_sales
        GROUP BY 
            cs_item_sk
    ) cs ON is.ws_item_sk = cs.cs_item_sk
),
top_selling_items AS (
    SELECT 
        ws_item_sk,
        web_sales_total,
        catalog_sales_total,
        combined_sales,
        RANK() OVER (ORDER BY combined_sales DESC) AS sales_rank
    FROM 
        ranked_sales
)
SELECT 
    ti.ws_item_sk AS item_id,
    ti.web_sales_total AS total_web_sales,
    ti.catalog_sales_total AS total_catalog_sales,
    ti.combined_sales,
    CASE 
        WHEN ti.combined_sales IS NULL THEN 'No Sales Data'
        WHEN ti.combined_sales > 1000 THEN 'High Seller'
        ELSE 'Regular Seller'
    END AS sales_category
FROM 
    top_selling_items ti
WHERE 
    ti.sales_rank <= 10
ORDER BY 
    ti.combined_sales DESC;
