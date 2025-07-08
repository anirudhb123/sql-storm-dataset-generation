
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_info AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
address_counts AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        LISTAGG(c.c_first_name || ' ' || c.c_last_name, ', ') WITHIN GROUP (ORDER BY c.c_customer_sk) AS customer_names
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_city
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    COALESCE(si.total_sales, 0) AS total_sales,
    COALESCE(si.order_count, 0) AS order_count,
    ac.customer_count,
    ac.customer_names
FROM 
    customer_info ci
LEFT JOIN 
    sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
LEFT JOIN 
    address_counts ac ON ci.ca_city = ac.ca_city
WHERE 
    ci.cd_gender = 'F' AND
    ci.ca_state = 'CA' AND
    COALESCE(si.total_sales, 0) > 1000 
ORDER BY 
    ci.ca_city, ci.full_name;
