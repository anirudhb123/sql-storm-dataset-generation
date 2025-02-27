
WITH RECURSIVE sales_data AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY cs_item_sk
),
top_items AS (
    SELECT 
        i.i_item_id, 
        s.total_quantity, 
        s.total_sales
    FROM sales_data s
    JOIN item i ON s.cs_item_sk = i.i_item_sk
    WHERE s.sales_rank <= 10
)
SELECT 
    w.w_warehouse_id, 
    COALESCE(t.total_quantity, 0) AS total_quantity,
    COALESCE(t.total_sales, 0) AS total_sales,
    AVG(CASE 
        WHEN t.total_sales > 0 THEN t.total_sales / NULLIF(t.total_quantity, 0) 
        ELSE NULL 
    END) AS avg_sales_per_item,
    COUNT(DISTINCT CASE WHEN t.total_sales > 0 THEN t.i_item_id END) AS distinct_sold_items
FROM warehouse w
LEFT JOIN top_items t ON w.w_warehouse_sk = t.cs_warehouse_sk
GROUP BY w.w_warehouse_id
ORDER BY w.w_warehouse_id;
