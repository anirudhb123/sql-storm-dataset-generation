
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        ws.net_paid,
        dd.d_year,
        COUNT(*) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    GROUP BY 
        ws.web_site_id, dd.d_year
),
YearlySales AS (
    SELECT 
        web_site_id,
        d_year,
        SUM(net_paid) AS total_revenue,
        SUM(total_sales) AS total_transactions
    FROM 
        SalesData
    GROUP BY 
        web_site_id, d_year
)
SELECT 
    web_site_id,
    d_year,
    total_revenue,
    total_transactions,
    ROUND(total_revenue / NULLIF(total_transactions, 0), 2) AS average_order_value
FROM 
    YearlySales
ORDER BY 
    d_year, web_site_id;
