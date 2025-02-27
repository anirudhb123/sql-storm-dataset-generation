
WITH processed_addresses AS (
    SELECT
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM
        customer_address
),
filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS last_purchase_date,
        DATEDIFF(CURRENT_DATE, d.d_date) AS days_since_last_purchase
    FROM
        customer c
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 1990
),
address_customer_details AS (
    SELECT
        f.c_customer_sk,
        f.full_name,
        p.full_address,
        p.ca_city,
        p.ca_state,
        p.ca_zip,
        p.ca_country,
        f.days_since_last_purchase
    FROM
        filtered_customers f
    LEFT JOIN processed_addresses p ON f.c_customer_sk = p.ca_address_sk
)
SELECT
    acd.full_name,
    acd.full_address,
    acd.ca_city,
    acd.ca_state,
    acd.ca_zip,
    acd.ca_country,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(acd.days_since_last_purchase) AS avg_days_since_last_purchase
FROM
    address_customer_details acd
LEFT JOIN web_sales ws ON acd.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY
    acd.full_name, acd.full_address, acd.ca_city, acd.ca_state, acd.ca_zip, acd.ca_country
ORDER BY
    total_sales DESC
LIMIT 100;
