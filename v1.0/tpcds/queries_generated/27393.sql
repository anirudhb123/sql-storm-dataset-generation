
WITH address_parts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_info AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        sa.full_address,
        si.total_sales,
        si.order_count
    FROM 
        customer_info ci
    JOIN 
        sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
    JOIN 
        address_parts sa ON ci.c_customer_sk = sa.ca_address_sk
    ORDER BY 
        si.total_sales DESC
    LIMIT 10
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    full_address,
    total_sales,
    order_count,
    CONCAT('Total sales: $', FORMAT(total_sales, 2)) AS formatted_total_sales
FROM 
    top_customers;
