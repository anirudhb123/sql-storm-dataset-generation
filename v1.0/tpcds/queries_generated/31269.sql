
WITH RECURSIVE sales_trend AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year 
    HAVING 
        d.d_year >= (SELECT MIN(d_year) FROM date_dim) 
        AND d.d_year <= (SELECT MAX(d_year) FROM date_dim)
),
item_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_ext_sales_price) AS total_revenue
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, 
        i.i_item_desc
),
high_performing_items AS (
    SELECT 
        is.i_item_sk,
        is.i_item_desc,
        is.total_quantity,
        is.avg_sales_price,
        is.total_revenue
    FROM 
        item_summary is
    JOIN 
        sales_trend st ON is.total_revenue > (SELECT AVG(total_sales) FROM sales_trend)
    WHERE 
        st.sales_rank <= 10
)
SELECT 
    h.i_item_sk,
    h.i_item_desc,
    COALESCE(h.total_quantity, 0) AS quantity_sold,
    ROUND(h.avg_sales_price, 2) AS average_price,
    ROUND(h.total_revenue, 2) AS total_revenue,
    CASE
        WHEN h.total_revenue IS NULL THEN 'No sales'
        ELSE 'Sales exist'
    END AS sales_status
FROM 
    high_performing_items h
LEFT JOIN 
    store_sales ss ON h.i_item_sk = ss.ss_item_sk
LEFT JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk 
WHERE 
    s.s_country = 'USA' 
    AND s.s_state IS NOT NULL
ORDER BY 
    h.total_revenue DESC
LIMIT 20;
