
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ws.ws_quantity) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        store s
    LEFT JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
    
    UNION ALL

    SELECT 
        sh.s_store_sk,
        sh.s_store_name,
        sh.total_sales + ws.ws_quantity AS total_sales,
        sh.sales_rank
    FROM 
        sales_hierarchy sh
    JOIN 
        web_sales ws ON sh.s_store_sk = ws.ws_warehouse_sk AND ws.ws_sales_price > 0
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(ws2.ws_sold_date_sk) FROM web_sales ws2)
)

SELECT 
    sh.s_store_name,
    sh.total_sales,
    CASE 
        WHEN sh.sales_rank = 1 THEN 'Top Performer' 
        WHEN sh.sales_rank = 2 THEN 'Second Place' 
        ELSE 'Other' 
    END AS store_status,
    RANK() OVER (ORDER BY sh.total_sales DESC) AS overall_rank,
    COALESCE(wp.wp_creation_date_sk, 0) AS web_page_creation_date
FROM 
    sales_hierarchy sh
LEFT JOIN 
    web_page wp ON sh.s_store_sk = wp.wp_web_page_sk
WHERE 
    sh.total_sales > (SELECT AVG(total_sales) FROM sales_hierarchy)
ORDER BY 
    sh.total_sales DESC;
