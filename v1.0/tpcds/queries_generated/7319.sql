
WITH SalesData AS (
    SELECT 
        ws.web_site_id, 
        c.c_gender, 
        SUM(ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        DENSE_RANK() OVER (PARTITION BY c.c_gender ORDER BY SUM(ws.ws_quantity) DESC) as sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        ws.web_site_id, c.c_gender
),
TopSales AS (
    SELECT 
        web_site_id, 
        c_gender, 
        total_sales, 
        avg_sales_price
    FROM 
        SalesData
    WHERE 
        sales_rank <= 10
)
SELECT 
    t.web_site_id, 
    t.c_gender,
    t.total_sales, 
    t.avg_sales_price, 
    w.w_warehouse_name, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM 
    TopSales t
JOIN 
    web_site w ON t.web_site_id = w.web_site_id
JOIN 
    web_sales ws ON t.web_site_id = ws.ws_web_site_sk
GROUP BY 
    t.web_site_id, t.c_gender, t.total_sales, t.avg_sales_price, w.w_warehouse_name
ORDER BY 
    t.total_sales DESC;
