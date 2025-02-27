
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', 
                ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip, ', ', ca.ca_country) AS full_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_info AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
rich_customers AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.full_address,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        si.total_sales,
        si.order_count
    FROM 
        customer_info ci
    JOIN 
        sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
    WHERE 
        si.total_sales > 1000
)
SELECT 
    full_name,
    full_address,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_sales,
    order_count
FROM 
    rich_customers
ORDER BY 
    total_sales DESC, 
    order_count DESC;
