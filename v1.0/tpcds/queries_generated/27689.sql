
WITH address_info AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
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
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        STRING_AGG(DISTINCT CONCAT(ca_address_id, '-', ca_city, '-', ca_state), '; ') AS address_details
    FROM 
        web_sales ws
    JOIN 
        customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ss.total_sales,
    ss.order_count,
    ss.address_details
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    ss.total_sales > 1000
ORDER BY 
    ss.total_sales DESC;
