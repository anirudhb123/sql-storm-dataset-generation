
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
item_sales AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    ss.d_year,
    ss.d_month_seq,
    ss.total_sales,
    ss.order_count,
    ss.avg_sales_price,
    tc.c_customer_id,
    tc.total_spent,
    is.total_quantity_sold
FROM 
    sales_summary ss
JOIN 
    top_customers tc ON ss.d_year = 2023
JOIN 
    item_sales is ON is.total_quantity_sold > 100
ORDER BY 
    ss.total_sales DESC;
