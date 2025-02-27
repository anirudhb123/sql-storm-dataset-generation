
WITH item_sales AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
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
        i.i_item_id, i.i_item_desc
), 
ranked_sales AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        (total_web_sales + total_catalog_sales + total_store_sales) AS total_sales,
        RANK() OVER (ORDER BY (total_web_sales + total_catalog_sales + total_store_sales) DESC) AS sales_rank
    FROM 
        item_sales i
)
SELECT 
    r.i_item_id,
    r.i_item_desc,
    r.total_web_sales,
    r.total_catalog_sales,
    r.total_store_sales,
    r.total_sales,
    CASE 
        WHEN r.total_sales = 0 THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status,
    (SELECT COUNT(*) 
     FROM customer c 
     WHERE c.c_current_cdemo_sk IN (
         SELECT cd.cd_demo_sk 
         FROM customer_demographics cd 
         WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
     )) AS female_married_customers_count
FROM 
    ranked_sales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_sales DESC;
