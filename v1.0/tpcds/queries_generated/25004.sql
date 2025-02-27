
WITH customer_details AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
qualified_customers AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        cd.ca_zip,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS total_orders
    FROM 
        customer_details cd
    LEFT JOIN 
        sales_data sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 5000 THEN 'High Value'
        WHEN total_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    qualified_customers
WHERE 
    cd_gender = 'F' 
    AND cd_cd_education_status LIKE '%Bachelor%'
ORDER BY 
    total_sales DESC
LIMIT 100;
