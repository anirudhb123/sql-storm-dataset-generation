
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id
)
SELECT 
    ws.web_site_id,
    ss.total_quantity,
    ss.total_sales
FROM 
    web_site ws
LEFT JOIN 
    sales_summary ss ON ws.web_site_id = ss.web_site_id
ORDER BY 
    ss.total_sales DESC;
