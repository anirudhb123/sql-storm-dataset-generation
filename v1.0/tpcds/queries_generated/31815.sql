
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_brand, 1 AS level
    FROM item
    WHERE i_brand IS NOT NULL
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_brand, ih.level + 1
    FROM item i
    JOIN item_hierarchy ih ON i.i_item_sk = ih.i_item_sk
),
sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month,
        iw.i_item_id AS item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY d.d_year, d.d_month_seq ORDER BY SUM(ws.ws_sales_price) DESC) AS item_rank
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    JOIN item iw ON ws.ws_item_sk = iw.i_item_sk
    WHERE d.d_year = 2023
    GROUP BY d.d_year, d.d_month_seq, iw.i_item_id
)
SELECT 
    sa.sales_year,
    sa.sales_month,
    sa.item_id,
    sa.total_quantity_sold,
    sa.total_sales,
    ih.i_brand,
    CASE 
        WHEN sa.total_sales > 1000 THEN 'High'
        WHEN sa.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM sales_summary sa
LEFT JOIN item_hierarchy ih ON sa.item_id = ih.i_item_id
WHERE sa.item_rank <= 5
ORDER BY sa.sales_year, sa.sales_month, sa.total_sales DESC;
