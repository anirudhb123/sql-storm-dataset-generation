
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    INNER JOIN 
        web_site w ON ws.web_site_sk = w.web_site_sk
    INNER JOIN 
        customer c ON ws.ship_customer_sk = c.c_customer_sk
    WHERE 
        w.web_open_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim)
        AND w.web_close_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.web_site_id
),
TopSales AS (
    SELECT 
        web_site_id,
        total_orders,
        total_sales
    FROM 
        RankedSales
    WHERE 
        rank <= 5
)
SELECT 
    w.web_site_id,
    w.web_name,
    ts.total_orders,
    ts.total_sales,
    ts.total_sales / NULLIF(ts.total_orders, 0) AS avg_sales_per_order
FROM 
    TopSales ts
INNER JOIN 
    web_site w ON ts.web_site_id = w.web_site_id
ORDER BY 
    ts.total_sales DESC;
