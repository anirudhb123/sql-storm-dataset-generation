
WITH address_info AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
    WHERE 
        ca_city LIKE 'San%'
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT 
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ws_ship_date_sk,
        ws_web_page_sk,
        CURRENT_DATE - d.d_date AS days_since_sale
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ai.full_address,
    SUM(sd.ws_quantity) AS total_quantity,
    SUM(sd.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT sd.ws_web_page_sk) AS distinct_web_pages,
    AVG(sd.days_since_sale) AS avg_days_since_sale
FROM 
    customer_info ci
JOIN 
    address_info ai ON ci.c_customer_id IN (SELECT c.c_customer_id FROM customer c WHERE c.c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_city = ai.ca_city))
JOIN 
    sales_data sd ON ci.c_customer_id = sd.ws_bill_customer_sk
GROUP BY 
    ci.full_name, ci.cd_gender, ci.cd_marital_status, ai.full_address
ORDER BY 
    total_sales DESC
LIMIT 100;
