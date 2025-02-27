
WITH combined_sales AS (
    SELECT 
        'web' AS source,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    
    UNION ALL
    
    SELECT 
        'catalog' AS source,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
    
    UNION ALL
    
    SELECT 
        'store' AS source,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_sales_price) AS total_sales
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
product_ranking AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        SUM(cs.total_quantity) AS total_quantity,
        SUM(cs.total_sales) AS total_sales,
        RANK() OVER (ORDER BY SUM(cs.total_sales) DESC) AS sales_rank
    FROM 
        item 
    JOIN 
        combined_sales cs ON item.i_item_sk = cs.ws_item_sk OR item.i_item_sk = cs.cs_item_sk OR item.i_item_sk = cs.ss_item_sk
    GROUP BY 
        item.i_item_id, item.i_item_desc
)
SELECT 
    pr.i_item_id,
    pr.i_item_desc,
    pr.total_quantity,
    pr.total_sales,
    pr.sales_rank
FROM 
    product_ranking pr
WHERE 
    pr.sales_rank <= 10
ORDER BY 
    pr.total_sales DESC;
