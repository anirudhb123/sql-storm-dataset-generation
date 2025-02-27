
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        d.d_moy IN (5, 6) -- May and June
    GROUP BY 
        ws.web_site_sk
), SalesStatistics AS (
    SELECT 
        r.web_site_sk, 
        r.total_sales,
        r.total_orders,
        AVG(r.total_sales) OVER () AS avg_sales,
        AVG(r.total_orders) OVER () AS avg_orders
    FROM 
        RankedSales r
)
SELECT 
    w.web_site_id,
    s.total_sales,
    s.total_orders,
    s.avg_sales,
    s.avg_orders,
    (s.total_sales - s.avg_sales) / s.avg_sales * 100 AS deviation_from_avg_sales_percentage,
    (s.total_orders - s.avg_orders) / s.avg_orders * 100 AS deviation_from_avg_orders_percentage
FROM 
    SalesStatistics s
JOIN 
    web_site w ON s.web_site_sk = w.web_site_sk
WHERE 
    s.sales_rank <= 10
ORDER BY 
    s.total_sales DESC;
