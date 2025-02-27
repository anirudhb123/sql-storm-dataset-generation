
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        SUM(ws.ws_ext_sales_price) AS total_sales, 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND dd.d_moy IN (11, 12) -- November and December
    GROUP BY 
        ws.web_site_sk
), HighPerformance AS (
    SELECT 
        r.web_site_sk,
        r.total_sales,
        r.total_orders,
        r.unique_customers,
        r.sales_rank,
        ROW_NUMBER() OVER (PARTITION BY r.sales_rank ORDER BY r.total_sales DESC) AS high_performance_rank
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 10
)
SELECT 
    w.web_site_id,
    h.total_sales,
    h.total_orders,
    h.unique_customers,
    h.high_performance_rank 
FROM 
    HighPerformance h
JOIN 
    web_site w ON h.web_site_sk = w.web_site_sk
ORDER BY 
    h.total_sales DESC;
