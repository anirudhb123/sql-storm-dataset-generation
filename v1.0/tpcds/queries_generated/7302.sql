
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws_sold_date_sk
),
top_websites AS (
    SELECT 
        web_site_sk, 
        total_quantity, 
        total_sales 
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 10
)
SELECT 
    w.web_site_id,
    w.web_name,
    tw.total_quantity,
    tw.total_sales,
    COALESCE(tw.total_sales / NULLIF(tw.total_quantity, 0), 0) AS avg_sales_price
FROM 
    top_websites tw
JOIN 
    web_site w ON tw.web_site_sk = w.web_site_sk
ORDER BY 
    tw.total_sales DESC;
