
WITH sales_summary AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_sold_quantity,
        SUM(cs_ext_sales_price) AS total_sales_amount
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450000 AND 2450060
    GROUP BY cs_item_sk
),
top_items AS (
    SELECT 
        cs.cs_item_sk,
        i.i_item_desc,
        s.total_sold_quantity,
        s.total_sales_amount,
        ROW_NUMBER() OVER (ORDER BY s.total_sales_amount DESC) AS sales_rank
    FROM sales_summary s
    JOIN item i ON s.cs_item_sk = i.i_item_sk
)
SELECT 
    ti.sales_rank,
    ti.i_item_desc,
    CASE 
        WHEN ti.total_sold_quantity IS NULL THEN 'No Sales'
        ELSE CAST(ti.total_sold_quantity AS VARCHAR)
    END AS quantity_sold,
    COALESCE(ROUND(ti.total_sales_amount, 2), 0.00) AS total_sales_amount,
    DENSE_RANK() OVER (ORDER BY ti.total_sales_amount DESC) AS sales_density
FROM top_items ti
WHERE ti.sales_rank <= 10
UNION ALL
SELECT 
    NULL AS sales_rank,
    'TOTAL' AS i_item_desc,
    SUM(ti.total_sold_quantity) AS quantity_sold,
    SUM(ti.total_sales_amount) AS total_sales_amount,
    NULL AS sales_density
FROM top_items ti
HAVING SUM(ti.total_sales_amount) > 0.00;
