
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND
        w.w_warehouse_state = 'CA'
    GROUP BY 
        w.w_warehouse_id, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq
),
top_customers AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_spent
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    ORDER BY 
        total_spent DESC
    LIMIT 10
)
SELECT 
    ss.w_warehouse_id,
    ss.c_first_name,
    ss.c_last_name,
    ss.total_quantity_sold,
    ss.total_sales_amount,
    ss.total_orders,
    tc.total_spent
FROM 
    sales_summary ss
JOIN 
    top_customers tc ON ss.ws_bill_customer_sk = tc.ws_bill_customer_sk
ORDER BY 
    ss.total_sales_amount DESC;
