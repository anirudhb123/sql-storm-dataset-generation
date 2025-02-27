
WITH sales_summary AS (
    SELECT 
        s.s_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity
    FROM 
        store_sales
    GROUP BY 
        s_store_sk
)
SELECT 
    ss.s_store_sk,
    ss.total_sales,
    ss.total_quantity,
    s.s_store_name,
    s.s_city,
    s.s_state
FROM 
    sales_summary ss
JOIN 
    store s ON ss.s_store_sk = s.s_store_sk
ORDER BY 
    total_sales DESC
LIMIT 10;
