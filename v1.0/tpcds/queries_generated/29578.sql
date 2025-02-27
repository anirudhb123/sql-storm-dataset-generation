
WITH formatted_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
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
        da.d_date AS registration_date
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN date_dim da ON c.c_first_sales_date_sk = da.d_date_sk
),
address_summary AS (
    SELECT 
        ca.ca_address_sk,
        COUNT(c.c_customer_sk) AS total_customers,
        STRING_AGG(DISTINCT ci.full_name, ', ') AS customer_names
    FROM formatted_addresses ca
    JOIN customer_info ci ON ci.c_customer_sk IN (
        SELECT c.c_customer_sk 
        FROM customer c WHERE c.c_current_addr_sk = ca.ca_address_sk
    )
    GROUP BY ca.ca_address_sk
)
SELECT 
    fa.full_address,
    fa.ca_city,
    fa.ca_state,
    fa.ca_zip,
    fa.ca_country,
    asum.total_customers,
    asum.customer_names
FROM formatted_addresses fa
LEFT JOIN address_summary asum ON fa.ca_address_sk = asum.ca_address_sk
WHERE fa.ca_country LIKE 'U%' AND asum.total_customers > 0
ORDER BY fa.ca_city, fa.ca_state;
