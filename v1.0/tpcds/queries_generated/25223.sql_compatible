
WITH customer_with_location AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        a.ca_zip
    FROM 
        customer c
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
high_value_customers AS (
    SELECT 
        cl.customer_name,
        cl.ca_city,
        cl.ca_state,
        cl.ca_country,
        cl.ca_zip,
        ss.total_sales,
        ss.order_count
    FROM 
        customer_with_location cl
    JOIN 
        sales_summary ss ON cl.c_customer_id = ss.ws_bill_customer_sk
    WHERE 
        ss.total_sales > 1000
)
SELECT 
    customer_name,
    ca_city,
    ca_state,
    ca_country,
    ca_zip,
    total_sales,
    order_count,
    CASE 
        WHEN order_count > 10 THEN 'Frequent'
        WHEN order_count BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Rare'
    END AS customer_segment
FROM 
    high_value_customers
ORDER BY 
    total_sales DESC, 
    customer_name;
