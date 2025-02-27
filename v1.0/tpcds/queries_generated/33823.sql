
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_manager,
        s_floor_space,
        0 AS level
    FROM store
    WHERE s_store_sk = (SELECT MIN(s_store_sk) FROM store)

    UNION ALL

    SELECT 
        s_store_sk,
        s_store_name,
        s_manager,
        s_floor_space,
        sh.level + 1
    FROM store s
    JOIN sales_hierarchy sh ON s.s_manager = sh.s_store_name
),
total_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales_price,
        COUNT(ws.ws_order_number) AS orders_count
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
customer_return_data AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY cr.cr_item_sk
),
combined_sales AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        COALESCE(ts.total_sales_price, 0) AS total_sales,
        COALESCE(crd.total_return_quantity, 0) AS total_returns,
        COALESCE(crd.total_return_amount, 0) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY COALESCE(ts.total_sales_price, 0) DESC) AS sales_rank
    FROM item i
    LEFT JOIN total_sales ts ON i.i_item_sk = ts.ws_item_sk
    LEFT JOIN customer_return_data crd ON i.i_item_sk = crd.cr_item_sk
),
final_report AS (
    SELECT 
        sh.s_store_name,
        sh.level,
        cs.i_product_name,
        cs.total_sales,
        cs.total_returns,
        cs.total_return_amount,
        (cs.total_sales - cs.total_return_amount) AS net_sales,
        DENSE_RANK() OVER (PARTITION BY sh.s_store_name ORDER BY (cs.total_sales - cs.total_return_amount) DESC) AS store_rank
    FROM sales_hierarchy sh
    JOIN combined_sales cs ON sh.s_store_sk IN (
        SELECT sr.s_store_sk 
        FROM store_returns sr 
        WHERE sr.s_returned_date_sk > 0
    )
)
SELECT
    s.s_store_name,
    f.level,
    f.i_product_name,
    f.total_sales,
    f.total_returns,
    f.net_sales,
    f.store_rank
FROM final_report f
JOIN sales_hierarchy s ON f.s_store_name = s.s_store_name
WHERE f.net_sales > 1000
ORDER BY f.store_rank, f.total_sales DESC;
