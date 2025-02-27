
WITH sales_summary AS (
    SELECT 
        d.d_year,
        c.c_state,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        d.d_year, c.c_state
), 
avg_sales AS (
    SELECT 
        d_year,
        c_state,
        AVG(total_sales) AS avg_sales_per_state
    FROM 
        sales_summary
    GROUP BY 
        d_year, c_state
)
SELECT 
    a.d_year,
    a.c_state,
    a.avg_sales_per_state,
    s.total_orders,
    s.unique_customers 
FROM 
    avg_sales a
JOIN 
    sales_summary s ON a.d_year = s.d_year AND a.c_state = s.c_state
ORDER BY 
    a.d_year, a.c_state;
