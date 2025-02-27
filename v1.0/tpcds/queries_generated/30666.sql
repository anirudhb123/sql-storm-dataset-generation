
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cs_order_number,
        cs_item_sk,
        cs_quantity,
        cs_sales_price,
        cs_bill_customer_sk,
        1 AS level
    FROM catalog_sales
    WHERE cs_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    
    UNION ALL
    
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_bill_customer_sk,
        h.level + 1
    FROM catalog_sales cs
    JOIN sales_hierarchy h ON cs.cs_order_number = h.cs_order_number
    WHERE h.level < 5
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(sh.cs_sales_price * sh.cs_quantity) AS total_sales,
    COUNT(DISTINCT sh.cs_order_number) AS order_count,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(sh.cs_sales_price * sh.cs_quantity) DESC) AS sales_rank,
    CASE 
        WHEN SUM(sh.cs_sales_price * sh.cs_quantity) IS NULL THEN 'No Sales'
        ELSE 'Sales Exists'
    END AS sales_status
FROM customer c
LEFT JOIN sales_hierarchy sh ON c.c_customer_sk = sh.cs_bill_customer_sk
WHERE c.c_birth_year IS NOT NULL
AND (c.c_first_name LIKE '%John%' OR c.c_first_name LIKE '%Jane%')
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
HAVING SUM(sh.cs_sales_price * sh.cs_quantity) > 1000
OR COUNT(DISTINCT sh.cs_order_number) > 5
ORDER BY total_sales DESC
LIMIT 100;

