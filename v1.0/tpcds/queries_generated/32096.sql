
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_quantity,
        cs_sales_price,
        1 AS level
    FROM catalog_sales
    WHERE cs_sales_price > 100
    UNION ALL
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity + sh.cs_quantity,
        cs.cs_sales_price,
        sh.level + 1
    FROM catalog_sales cs
    JOIN sales_hierarchy sh ON cs.cs_order_number = sh.cs_order_number
    WHERE cs.cs_quantity > sh.cs_quantity
)
, top_items AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        SUM(sh.cs_quantity) AS total_quantity,
        SUM(sh.cs_sales_price * sh.cs_quantity) AS total_sales
    FROM item i
    JOIN sales_hierarchy sh ON i.i_item_sk = sh.cs_item_sk
    GROUP BY i.i_item_id, i.i_product_name
    ORDER BY total_sales DESC
    LIMIT 10
)
SELECT 
    t.i_item_id,
    t.i_product_name,
    t.total_quantity,
    t.total_sales,
    COALESCE(p.p_discount_active, 'N') AS discount_active,
    CASE 
        WHEN t.total_sales > 1000 THEN 'High Sales'
        WHEN t.total_sales BETWEEN 500 AND 1000 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM top_items t
LEFT JOIN promotion p ON t.i_item_id = p.p_item_sk
WHERE t.total_quantity IS NOT NULL
AND (t.total_sales IS NOT NULL OR p.p_start_date_sk IS NULL)
ORDER BY t.total_sales DESC;
