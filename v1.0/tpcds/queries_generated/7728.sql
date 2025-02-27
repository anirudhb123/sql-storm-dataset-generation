
WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        c.c_gender,
        c.c_birth_year,
        d.d_year,
        d.d_month_seq,
        t.t_hour
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE 
        d.d_year = 2023
        AND ws.ws_quantity > 0
),
aggregated_sales AS (
    SELECT
        c_gender,
        d_year,
        d_month_seq,
        t_hour,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_items_sold,
        SUM(ws_net_paid) AS total_revenue
    FROM 
        sales_data
    GROUP BY 
        c_gender, d_year, d_month_seq, t_hour
)
SELECT 
    c_gender,
    d_year,
    d_month_seq,
    t_hour,
    total_orders,
    total_items_sold,
    total_revenue,
    CASE
        WHEN total_revenue > 10000 THEN 'High'
        WHEN total_revenue BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_category
FROM 
    aggregated_sales
ORDER BY 
    d_year, d_month_seq, t_hour, c_gender;
