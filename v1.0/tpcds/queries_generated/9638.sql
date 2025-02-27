
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws_sold_date_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws_sold_date_sk
),
SalesSummary AS (
    SELECT 
        ws.web_site_sk,
        SUM(total_sales) AS total_sales,
        SUM(order_count) AS total_orders
    FROM 
        RankedSales rs
    GROUP BY 
        ws.web_site_sk
)
SELECT 
    w.warehouse_name,
    ss.total_sales,
    ss.total_orders,
    COALESCE(ss.total_sales / NULLIF(ss.total_orders, 0), 0) AS avg_sales_order
FROM 
    warehouse w
LEFT JOIN 
    SalesSummary ss ON w.warehouse_sk = ss.web_site_sk
WHERE 
    ss.total_sales > 100000
ORDER BY 
    avg_sales_order DESC
LIMIT 10;
