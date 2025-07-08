
WITH RECURSIVE sales_data AS (
    SELECT ws_item_sk,
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_sales_price) AS total_sales,
           SUM(ws_ext_discount_amt) AS total_discount
    FROM web_sales
    WHERE ws_sold_date_sk >= (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_year = 2023 
    )
    GROUP BY ws_item_sk
    UNION ALL
    SELECT ws_item_sk,
           total_quantity,
           total_sales * 1.05 AS total_sales, 
           total_discount * 1.05 AS total_discount
    FROM sales_data
    WHERE total_sales < 10000
),
ranked_sales AS (
    SELECT sd.ws_item_sk,
           sd.total_quantity,
           sd.total_sales,
           sd.total_discount,
           RANK() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_sales DESC) AS sales_rank
    FROM sales_data sd
),
filtered_sales AS (
    SELECT rs.ws_item_sk, 
           rs.total_sales,
           rs.total_discount,
           ci.i_brand
    FROM ranked_sales rs
    JOIN item ci ON rs.ws_item_sk = ci.i_item_sk
    WHERE rs.sales_rank = 1 AND ci.i_category = 'Beverages'
)
SELECT fs.ws_item_sk,
       fs.total_sales,
       fs.total_discount,
       COALESCE(NULLIF(fs.total_sales - fs.total_discount, 0), NULL) AS net_sales_adjusted,
       CASE 
           WHEN fs.total_sales > 5000 THEN 'High Performer' 
           ELSE 'Low Performer' 
       END AS performance_category
FROM filtered_sales fs
LEFT JOIN warehouse w ON fs.ws_item_sk = w.w_warehouse_sk
WHERE w.w_warehouse_sq_ft > 2000
ORDER BY fs.total_sales DESC;
