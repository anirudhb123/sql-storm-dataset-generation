
WITH SalesData AS (
    SELECT 
        d.d_year, 
        d.d_month_seq, 
        c.c_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_revenue,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue_inc_tax,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq, c.c_gender
),
RankedSales AS (
    SELECT 
        d_year, 
        d_month_seq, 
        c_gender, 
        total_orders, 
        total_revenue, 
        total_revenue_inc_tax,
        total_quantity_sold,
        RANK() OVER (PARTITION BY d_year ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        SalesData
)
SELECT 
    d_year, 
    d_month_seq, 
    c_gender, 
    total_orders, 
    total_revenue,
    total_revenue_inc_tax,
    total_quantity_sold 
FROM 
    RankedSales
WHERE 
    revenue_rank <= 10
ORDER BY 
    d_year, 
    d_month_seq, 
    revenue_rank;
