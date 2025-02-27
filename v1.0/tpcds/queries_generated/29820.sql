
WITH formatted_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, COALESCE(ca_suite_number, '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        addr.full_address,
        addr.ca_city,
        addr.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        formatted_addresses addr ON c.c_current_addr_sk = addr.ca_address_sk
),
sales_summary AS (
    SELECT 
        c.customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        customer_info c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    si.total_sales,
    si.total_orders,
    ci.ca_city,
    ci.ca_state,
    CASE 
        WHEN si.total_sales IS NOT NULL AND si.total_sales > 1000 THEN 'High Value Customer'
        WHEN si.total_sales IS NOT NULL AND si.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary si ON ci.c_customer_sk = si.customer_sk
WHERE 
    ci.cd_gender = 'F' 
    AND ci.ca_state IN ('CA', 'TX')
ORDER BY 
    total_sales DESC
LIMIT 50;
