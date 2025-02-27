
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
TopWebsites AS (
    SELECT 
        web_site_id,
        total_quantity,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 3
)
SELECT 
    w.web_name,
    tw.total_quantity,
    tw.total_sales,
    ROUND(tw.total_sales / NULLIF(tw.total_quantity, 0), 2) AS avg_sales_price_per_item
FROM 
    TopWebsites tw
JOIN 
    web_site w ON tw.web_site_id = w.web_site_id
ORDER BY 
    tw.total_sales DESC;
