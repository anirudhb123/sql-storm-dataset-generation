
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk
), 
high_value_customers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        ss.total_sales,
        ss.total_orders
    FROM 
        customer AS c
    JOIN 
        sales_summary AS ss ON c.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        ss.total_sales >= 10000
),
customer_addresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        hlc.total_sales
    FROM 
        customer_address AS ca
    LEFT JOIN 
        high_value_customers AS hlc ON hlc.c_customer_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = hlc.c_customer_sk)
),
shipping_mode AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(DISTINCT ws_order_number) AS orders_count
    FROM 
        web_sales AS ws
    JOIN 
        ship_mode AS sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
)
SELECT 
    hvc.c_first_name || ' ' || hvc.c_last_name AS customer_name,
    ca.ca_city,
    ca.ca_state,
    sm.sm_type AS shipping_type,
    hvc.total_sales,
    hvc.total_orders
FROM 
    high_value_customers AS hvc
JOIN 
    customer_addresses AS ca ON hvc.c_customer_sk = ca.total_sales
JOIN 
    shipping_mode AS sm ON sm.orders_count = (SELECT MAX(orders_count) FROM shipping_mode)
WHERE 
    ca.ca_country = 'USA'
ORDER BY 
    hvc.total_sales DESC
FETCH FIRST 10 ROWS ONLY;
