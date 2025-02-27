
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
TopSales AS (
    SELECT 
        web_site_id,
        total_quantity,
        total_sales,
        order_count
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    T.web_site_id,
    T.total_quantity,
    T.total_sales,
    T.order_count,
    COALESCE(CAST(D.avg_return_rate AS DECIMAL(5,2)), 0) AS avg_return_rate
FROM 
    TopSales T
LEFT JOIN (
    SELECT 
        wr.web_site_sk,
        COUNT(wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT wr.wr_order_number) AS total_orders,
        (COUNT(wr.wr_order_number) * 1.0 / NULLIF(COUNT(DISTINCT wr.wr_order_number), 0)) AS avg_return_rate
    FROM 
        web_returns wr
    JOIN 
        web_sales ws ON wr.wr_order_number = ws.ws_order_number
    GROUP BY 
        wr.web_site_sk
) D ON T.web_site_id = D.web_site_sk
ORDER BY 
    T.total_sales DESC;
