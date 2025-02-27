
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
TopWebSites AS (
    SELECT 
        web_site_id, 
        total_sales, 
        total_orders 
    FROM 
        RankedSales 
    WHERE 
        sales_rank <= 10
)
SELECT 
    ws.web_site_id, 
    ws.total_sales, 
    ws.total_orders, 
    ROUND(ws.total_sales / NULLIF(ws.total_orders, 0), 2) AS avg_order_value
FROM 
    TopWebSites ws
ORDER BY 
    ws.total_sales DESC;
