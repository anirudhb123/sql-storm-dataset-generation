
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
item_sales AS (
    SELECT 
        i.item_id,
        i.i_current_price,
        COALESCE(sd.total_sales, 0) AS total_sales,
        sd.total_orders,
        CASE 
            WHEN sd.total_sales IS NULL THEN 'No sales'
            WHEN sd.total_sales > 1000 THEN 'High sales'
            ELSE 'Low sales'
        END AS sales_category
    FROM 
        item i
    LEFT JOIN 
        sales_data sd ON i.i_item_sk = sd.ws_item_sk
),
filtered_sales AS (
    SELECT 
        is.item_id,
        is.i_current_price,
        is.total_sales,
        is.total_orders,
        is.sales_category,
        DENSE_RANK() OVER (PARTITION BY is.sales_category ORDER BY is.total_sales DESC) AS sales_rank
    FROM 
        item_sales is
    WHERE 
        is.total_sales > 0
)
SELECT 
    fs.item_id,
    fs.i_current_price,
    fs.total_sales,
    fs.total_orders,
    fs.sales_category,
    fs.sales_rank,
    (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk IS NOT NULL) AS total_customers,
    (SELECT AVG(hd_dep_count) FROM household_demographics) AS avg_dependent_count
FROM 
    filtered_sales fs
WHERE 
    fs.sales_rank <= 5
ORDER BY 
    fs.sales_category, fs.total_sales DESC;
