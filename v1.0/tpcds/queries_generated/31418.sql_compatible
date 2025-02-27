
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY 
        cs_item_sk
),
ranked_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    rs.total_quantity,
    rs.total_sales,
    COALESCE(NULLIF(rs.total_sales, 0), 'N/A') AS conditional_sales,
    (SELECT COUNT(DISTINCT c.c_customer_sk)
     FROM customer c
     WHERE c.c_current_cdemo_sk IN (
         SELECT cd_demo_sk 
         FROM customer_demographics 
         WHERE cd_marital_status = 'M'
     )) AS married_customer_count,
    (SELECT AVG(hd_dep_count) 
     FROM household_demographics 
     WHERE hd_income_band_sk IS NOT NULL) AS avg_dependency_count
FROM 
    ranked_sales rs
JOIN 
    item i ON rs.ws_item_sk = i.i_item_sk
WHERE 
    rs.sales_rank <= 10
OR 
    (rs.total_quantity > 500 AND rs.total_sales < 1000)
ORDER BY 
    rs.total_sales DESC;
