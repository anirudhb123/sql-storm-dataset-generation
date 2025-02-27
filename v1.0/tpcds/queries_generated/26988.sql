
WITH address_part AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        address_part.full_address,
        address_part.ca_city,
        address_part.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        address_part ON c.c_current_addr_sk = address_part.ca_address_sk
),
sales_data AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_paid) AS total_sales,
        COUNT(ws.order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.bill_customer_sk
),
final_result AS (
    SELECT 
        customer_info.full_name,
        customer_info.cd_gender,
        customer_info.cd_marital_status,
        customer_info.cd_purchase_estimate,
        sales_data.total_sales,
        sales_data.order_count,
        CASE 
            WHEN sales_data.total_sales > 1000 THEN 'High Value'
            WHEN sales_data.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer_info
    LEFT JOIN 
        sales_data ON customer_info.c_customer_sk = sales_data.bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_purchase_estimate,
    total_sales,
    order_count,
    customer_value
FROM 
    final_result
WHERE 
    cd_gender = 'F'
ORDER BY 
    total_sales DESC, order_count DESC;
