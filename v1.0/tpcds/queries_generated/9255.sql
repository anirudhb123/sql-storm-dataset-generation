
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
TopSales AS (
    SELECT 
        web_site_id,
        total_sales,
        total_orders,
        avg_sales_price
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    t.web_site_id,
    t.total_sales,
    t.total_orders,
    t.avg_sales_price,
    w.w_warehouse_name,
    w.w_country
FROM 
    TopSales t
JOIN 
    warehouse w ON t.web_site_id = w.w_warehouse_id
ORDER BY 
    t.total_sales DESC;
