
WITH sales_summary AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_net_paid) AS total_sales, 
        COUNT(ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
), ranked_sales AS (
    SELECT 
        customer_id,
        c_first_name,
        c_last_name,
        total_sales,
        total_orders,
        last_purchase_date,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    r.customer_id,
    r.c_first_name,
    r.c_last_name,
    r.total_sales,
    r.total_orders,
    r.last_purchase_date
FROM 
    ranked_sales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_sales DESC;
