
WITH RankedSales AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_moy BETWEEN 1 AND 6
    GROUP BY 
        ws.web_site_id
),
TopWebsites AS (
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
    w.web_name,
    tw.total_sales,
    tw.total_orders,
    CASE 
        WHEN tw.total_sales > 500000 THEN 'High Performer'
        WHEN tw.total_sales > 200000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    web_site w
JOIN 
    TopWebsites tw ON w.web_site_id = tw.web_site_id
ORDER BY 
    tw.total_sales DESC;
