
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        ws.web_site_id
),
TopWebSites AS (
    SELECT 
        web_site_id,
        total_sales,
        order_count
    FROM 
        RankedSales
    WHERE 
        rank <= 5
)
SELECT 
    w.web_name,
    w.web_city,
    w.web_state,
    tw.total_sales,
    tw.order_count,
    w.web_tax_percentage,
    (tw.total_sales * w.web_tax_percentage / 100) AS estimated_tax
FROM 
    TopWebSites tw
JOIN 
    web_site w ON tw.web_site_id = w.web_site_id
ORDER BY 
    tw.total_sales DESC;
