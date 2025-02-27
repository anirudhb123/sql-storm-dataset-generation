
WITH address_parts AS (
    SELECT 
        ca_address_sk,
        CONCAT(COALESCE(ca_street_number, ''), ' ', COALESCE(ca_street_name, ''), ' ', COALESCE(ca_street_type, '')) AS full_address,
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
        c.c_first_name,
        c.c_last_name,
        c.email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ss_customer_sk,
        COUNT(*) AS total_sales,
        SUM(ss_sales_price) AS total_sales_value
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
)
SELECT 
    ci.full_name,
    ci.c_email_address,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.cd_credit_rating,
    COUNT(DISTINCT ss.total_sales) AS total_transactions,
    SUM(ss.total_sales_value) AS total_spent,
    ap.full_address,
    ap.ca_city,
    ap.ca_state,
    ap.ca_zip,
    ap.ca_country
FROM 
    customer_info ci
JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.ss_customer_sk
JOIN 
    customer_address ca ON ci.c_current_addr_sk = ca.ca_address_sk_sk
JOIN 
    address_parts ap ON ca.ca_address_sk = ap.ca_address_sk
WHERE 
    ci.cd_purchase_estimate > 500 AND 
    ci.cd_gender = 'M'
GROUP BY 
    ci.full_name, 
    ci.c_email_address,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.cd_credit_rating,
    ap.full_address,
    ap.ca_city,
    ap.ca_state,
    ap.ca_zip,
    ap.ca_country
ORDER BY 
    total_spent DESC
LIMIT 100;
