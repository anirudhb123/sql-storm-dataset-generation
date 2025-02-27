
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(
            TRIM(ca_street_number), ' ', 
            TRIM(ca_street_name), ' ', 
            TRIM(ca_street_type), ' ',
            COALESCE(TRIM(ca_suite_number), ''),
            CASE 
                WHEN TRIM(ca_suite_number) IS NOT NULL THEN ' ' 
                ELSE '' 
            END,
            TRIM(ca_city), ', ',
            TRIM(ca_state), ' ',
            TRIM(ca_zip), ' ',
            TRIM(ca_country)
        ) AS full_address
    FROM customer_address
),
customer_full_name AS (
    SELECT 
        c_customer_sk,
        CONCAT(
            TRIM(c_salutation), ' ',
            TRIM(c_first_name), ' ',
            TRIM(c_last_name)
        ) AS full_name
    FROM customer
),
date_info AS (
    SELECT 
        d_date_sk,
        DATE_FORMAT(d_date, '%Y-%m-%d') AS formatted_date,
        d_day_name
    FROM date_dim
)
SELECT 
    cfn.full_name,
    pa.full_address,
    di.formatted_date,
    di.d_day_name
FROM customer_full_name cfn
JOIN processed_addresses pa ON cfn.c_customer_sk = pa.ca_address_sk
JOIN date_info di ON di.d_date_sk = cfn.c_customer_sk
WHERE 
    di.d_day_name IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')
ORDER BY 
    di.formatted_date, cfn.full_name;
