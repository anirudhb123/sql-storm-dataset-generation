
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_birth_month = 12
),
sales_data AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales AS ws 
    GROUP BY 
        ws.bill_customer_sk
),
customer_sales_data AS (
    SELECT
        cd.c_customer_id,
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        COALESCE(sd.total_sales, 0) AS total_sales
    FROM 
        customer_data AS cd
    LEFT JOIN 
        sales_data AS sd ON cd.c_customer_id = sd.bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    total_sales,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    customer_sales_data
ORDER BY 
    total_sales DESC;
