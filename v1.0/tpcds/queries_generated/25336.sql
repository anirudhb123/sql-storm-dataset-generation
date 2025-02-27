
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        a.ca_city,
        a.ca_state,
        d.d_year,
        d.d_month_seq,
        d.d_dom
    FROM 
        customer c
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
detailed_info AS (
    SELECT 
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        ci.ca_city,
        ci.ca_state,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS total_orders
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_data sd ON ci.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    c.ca_city,
    c.ca_state,
    d.total_sales,
    d.total_orders,
    (d.total_sales / NULLIF(d.total_orders, 0)) AS avg_order_value 
FROM 
    detailed_info d
JOIN 
    customer_info c ON d.c_customer_id = c.c_customer_id
WHERE 
    c.ca_state = 'CA' AND 
    d.total_sales > 1000
ORDER BY 
    avg_order_value DESC
LIMIT 10;
