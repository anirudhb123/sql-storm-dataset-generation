
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        (cd.cd_marital_status = 'M' OR cd.cd_marital_status = 'S')
),
sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS orders_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
enriched_data AS (
    SELECT 
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        cd.ca_city,
        cd.ca_state,
        sd.total_sales,
        sd.orders_count
    FROM 
        customer_data cd
    LEFT JOIN 
        sales_data sd ON cd.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    c.ca_city,
    c.ca_state,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.orders_count, 0) AS orders_count,
    CASE 
        WHEN COALESCE(sd.total_sales, 0) > 1000 THEN 'High Value Customer'
        WHEN COALESCE(sd.total_sales, 0) BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment
FROM 
    enriched_data c
ORDER BY 
    total_sales DESC
LIMIT 100;
