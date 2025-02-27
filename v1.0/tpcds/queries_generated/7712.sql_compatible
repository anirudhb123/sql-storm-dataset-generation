
WITH SalesData AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        c.c_country,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq, c.c_country
),
SalesRanked AS (
    SELECT 
        d_year,
        d_month_seq,
        c_country,
        total_sales,
        total_orders,
        avg_order_value,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    d_year,
    d_month_seq,
    c_country,
    total_sales,
    total_orders,
    avg_order_value,
    sales_rank
FROM 
    SalesRanked
WHERE 
    sales_rank <= 10
ORDER BY 
    d_year, d_month_seq, sales_rank;
