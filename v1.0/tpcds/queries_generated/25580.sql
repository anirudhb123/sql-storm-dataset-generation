
WITH address_details AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
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
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ad.full_address,
        ad.ca_city,
        ad.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        address_details ad ON c.c_current_addr_sk = ad.ca_address_sk
),
sales_info AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        wd.d_date AS sale_date
    FROM 
        web_sales ws
    JOIN 
        date_dim wd ON ws.ws_sold_date_sk = wd.d_date_sk
),
benchmark AS (
    SELECT 
        ci.customer_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        SUM(si.ws_quantity) AS total_quantity,
        SUM(si.ws_net_paid) AS total_sales,
        COUNT(DISTINCT si.ws_order_number) AS total_orders
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
    GROUP BY 
        ci.customer_name, ci.cd_gender, ci.cd_marital_status, ci.cd_education_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    AVG(total_quantity) AS avg_quantity,
    AVG(total_sales) AS avg_sales,
    COUNT(customer_name) AS customer_count
FROM 
    benchmark
GROUP BY 
    cd_gender, cd_marital_status, cd_education_status
ORDER BY 
    cd_gender, cd_marital_status, cd_education_status;
