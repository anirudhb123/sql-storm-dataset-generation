
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_floor_space,
        1 AS level
    FROM 
        store
    WHERE 
        s_closed_date_sk IS NULL

    UNION ALL

    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_floor_space,
        level + 1
    FROM 
        sales_hierarchy sh
    JOIN 
        store s ON s.s_store_sk = sh.s_store_sk
    WHERE 
        s.s_closed_date_sk IS NULL AND sh.level < 5
),
daily_sales AS (
    SELECT 
        d.d_date,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    JOIN 
        date_dim d ON d.d_date_sk = ws_sold_date_sk
    GROUP BY 
        d.d_date
),
high_sales_dates AS (
    SELECT 
        d.d_date,
        d.d_mo,
        ds.total_sales,
        ROW_NUMBER() OVER (PARTITION BY d.d_mo ORDER BY ds.total_sales DESC) AS rnk
    FROM 
        daily_sales ds
    JOIN 
        date_dim d ON d.d_date = ds.d_date
)
SELECT 
    s.s_store_name,
    sh.level,
    COALESCE(hd.bd_income_band, 'Unknown') AS income_band,
    hs.d_date,
    hs.total_sales
FROM 
    sales_hierarchy sh
LEFT JOIN 
    household_demographics hd ON sh.s_store_sk = hd.hd_demo_sk
JOIN 
    high_sales_dates hs ON hs.rnk <= 10
WHERE 
    sh.s_number_employees > 100
ORDER BY 
    sh.level, hs.total_sales DESC;
