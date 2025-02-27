
WITH RankedSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY year(d.d_date) ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        w.w_warehouse_id, year(d.d_date)
),
TopSales AS (
    SELECT 
        warehouse_id,
        total_sales,
        order_count
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    t.warehouse_id,
    t.total_sales,
    t.order_count,
    ROUND(t.total_sales / t.order_count, 2) AS average_order_value
FROM 
    TopSales t
ORDER BY 
    t.total_sales DESC;
