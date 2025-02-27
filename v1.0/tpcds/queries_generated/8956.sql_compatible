
WITH ranked_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND d.d_moy IN (1, 2)
    GROUP BY 
        c.c_customer_id
),
high_value_customers AS (
    SELECT 
        c_customer_id AS customer_id, 
        total_sales,
        order_count
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 10
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    hvc.total_sales,
    hvc.order_count,
    a.ca_city,
    w.w_warehouse_name
FROM 
    high_value_customers hvc
JOIN 
    customer c ON hvc.customer_id = c.c_customer_id
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
JOIN 
    warehouse w ON w.w_warehouse_sk IN (SELECT DISTINCT ws.ws_warehouse_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk)
ORDER BY 
    hvc.total_sales DESC;
