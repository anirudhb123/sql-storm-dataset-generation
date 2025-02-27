
WITH RECURSIVE sales_summary AS (
    SELECT 
        SUM(ws_ext_sales_price) AS total_sales,
        s_store_id,
        d_year,
        ROW_NUMBER() OVER (PARTITION BY s_store_id, d_year ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        store s ON ws.ws_store_sk = s.s_store_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        s_store_id, d_year
), seasonal_sales AS (
    SELECT 
        s_store_id,
        d_year,
        SUM(total_sales) AS annual_sales
    FROM 
        sales_summary
    WHERE 
        sales_rank <= 10
    GROUP BY 
        s_store_id, d_year
), recent_sales AS (
    SELECT 
        s_store_id,
        d_year,
        SUM(total_sales) AS recent_total_sales
    FROM 
        sales_summary
    WHERE 
        d_year >= (SELECT MAX(d_year) - 1 FROM date_dim)
    GROUP BY 
        s_store_id, d_year
)
SELECT 
    s_store.s_store_name,
    COALESCE(seasonal_sales.annual_sales, 0) AS top_annual_sales,
    COALESCE(recent_sales.recent_total_sales, 0) AS recent_total_sales,
    (COALESCE(seasonal_sales.annual_sales, 0) - COALESCE(recent_sales.recent_total_sales, 0)) AS sales_difference
FROM 
    store s
LEFT JOIN 
    seasonal_sales ON s.s_store_id = seasonal_sales.s_store_id
LEFT JOIN 
    recent_sales ON s.s_store_id = recent_sales.s_store_id
WHERE 
    s.s_state = 'CA'
ORDER BY 
    sales_difference DESC
LIMIT 20;
