
WITH sales_summary AS (
    SELECT 
        d.d_year,
        c.c_state,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2022
    GROUP BY 
        d.d_year, c.c_state
), sales_ranked AS (
    SELECT 
        d_year, 
        c_state,
        total_sales, 
        total_orders, 
        avg_sales_price,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)

SELECT 
    d_year,
    c_state,
    total_sales,
    total_orders,
    avg_sales_price,
    sales_rank
FROM 
    sales_ranked
WHERE 
    sales_rank <= 5
ORDER BY 
    d_year, sales_rank;
