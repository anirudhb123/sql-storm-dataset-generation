
WITH address_details AS (
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
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ad ON c.c_current_addr_sk = ad.ca_address_sk
),
sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
benchmark_analysis AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        sd.total_sales,
        sd.order_count,
        CASE 
            WHEN sd.order_count > 5 THEN 'Frequent Shopper'
            WHEN sd.order_count BETWEEN 2 AND 5 THEN 'Moderate Shopper'
            ELSE 'Rare Shopper'
        END AS shopping_frequency
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    *,
    LENGTH(full_name) AS name_length,
    UPPER(cd_gender) AS gender_upper,
    LOWER(CASE WHEN cd_marital_status = 'M' THEN 'married' ELSE 'single' END) AS marital_status_lower,
    CONCAT(ca_city, ', ', ca_state, ' ', ca_country) AS full_location
FROM 
    benchmark_analysis
ORDER BY 
    total_sales DESC, name_length ASC;
