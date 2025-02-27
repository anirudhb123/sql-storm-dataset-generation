
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        c.c_email_address,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
MergedInfo AS (
    SELECT 
        ci.full_name,
        ci.c_email_address,
        ci.cd_gender,
        si.total_sales,
        si.order_count,
        si.total_discount,
        (CASE 
            WHEN si.total_sales >= 1000 THEN 'High Value'
            WHEN si.total_sales >= 500 THEN 'Medium Value'
            ELSE 'Low Value' 
        END) AS customer_value_category
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_id = si.ws_bill_customer_sk
)
SELECT 
    customer_value_category,
    cd_gender,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS avg_sales,
    AVG(order_count) AS avg_order_count
FROM 
    MergedInfo
GROUP BY 
    customer_value_category, cd_gender
ORDER BY 
    customer_value_category, cd_gender;
