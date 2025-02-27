
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id, ws_sold_date_sk
),
TopSales AS (
    SELECT 
        web_site_id,
        ws_sold_date_sk,
        total_sales,
        order_count
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    dd.d_date AS sales_date,
    ts.web_site_id,
    ts.total_sales,
    ts.order_count,
    (SELECT COUNT(*) FROM customer c WHERE c.c_current_cdemo_sk IS NOT NULL) AS distinct_customers
FROM 
    TopSales ts
INNER JOIN 
    date_dim dd ON ts.ws_sold_date_sk = dd.d_date_sk
ORDER BY 
    dd.d_date, ts.total_sales DESC;
