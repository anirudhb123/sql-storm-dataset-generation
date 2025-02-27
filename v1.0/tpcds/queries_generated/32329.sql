
WITH RECURSIVE sales_cte AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_sales,
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
    UNION ALL
    SELECT 
        c.cs_item_sk,
        SUM(c.cs_quantity) + s.total_quantity,
        SUM(c.cs_net_paid) + s.total_sales,
        level + 1
    FROM 
        catalog_sales c
    JOIN 
        sales_cte s ON c.cs_item_sk = s.ss_item_sk
    GROUP BY 
        c.cs_item_sk, s.total_quantity, s.total_sales, level
), 
ranked_sales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        COALESCE(s.total_quantity, 0) AS total_quantity,
        COALESCE(s.total_sales, 0) AS total_sales,
        RANK() OVER (PARTITION BY item.i_item_id ORDER BY COALESCE(s.total_sales, 0) DESC) AS sales_rank
    FROM 
        item
    LEFT JOIN 
        sales_cte s ON item.i_item_sk = s.ss_item_sk
)
SELECT 
    r.i_item_id,
    r.i_product_name,
    r.total_quantity,
    r.total_sales,
    r.sales_rank,
    CASE 
        WHEN r.sales_rank = 1 THEN 'Top Seller'
        WHEN r.total_quantity > 100 THEN 'High Volume'
        ELSE 'Regular'
    END AS sales_category
FROM 
    ranked_sales r
WHERE 
    r.total_sales >= 1000
    OR r.total_quantity IS NULL
ORDER BY 
    r.sales_rank;
