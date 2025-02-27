
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        ws.web_site_id
),
TopSales AS (
    SELECT 
        rs.web_site_id,
        rs.total_sales,
        rs.total_orders
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 5
)
SELECT 
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    ts.total_sales,
    ts.total_orders
FROM 
    TopSales ts
JOIN 
    warehouse w ON ts.web_site_id = w.w_warehouse_id
ORDER BY 
    ts.total_sales DESC;
