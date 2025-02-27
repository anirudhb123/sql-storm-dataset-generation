
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopSpenders AS (
    SELECT 
        c.customer_sk, 
        c.first_name, 
        c.last_name, 
        cs.total_sales
    FROM 
        CustomerSales AS cs
    JOIN 
        customer AS c ON cs.c_customer_sk = c.c_customer_sk
    ORDER BY 
        cs.total_sales DESC
    LIMIT 10
),
SalesSummary AS (
    SELECT 
        d.d_year AS sales_year, 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_revenue,
        AVG(ws.ws_ext_sales_price) AS avg_order_value
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    ts.first_name, 
    ts.last_name, 
    ts.total_sales, 
    ss.sales_year, 
    ss.total_orders, 
    ss.total_revenue, 
    ss.avg_order_value
FROM 
    TopSpenders AS ts
JOIN 
    SalesSummary AS ss ON ts.total_sales > ss.total_revenue / 100
ORDER BY 
    ss.total_revenue DESC, ts.total_sales DESC;
