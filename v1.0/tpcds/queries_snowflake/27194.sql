
WITH address_summary AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        LISTAGG(DISTINCT CONCAT(ca_street_name, ' ', ca_street_type), ', ') WITHIN GROUP (ORDER BY ca_street_name) AS all_street_names,
        LISTAGG(DISTINCT ca_suite_number, ', ') WITHIN GROUP (ORDER BY ca_suite_number) AS all_suites,
        LISTAGG(DISTINCT ca_zip, ', ') WITHIN GROUP (ORDER BY ca_zip) AS all_zip_codes
    FROM 
        customer_address
    WHERE 
        ca_state = 'CA'
    GROUP BY 
        ca_city
),
customer_summary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        LISTAGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), ', ') WITHIN GROUP (ORDER BY c_first_name) AS all_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd_marital_status = 'M'
    GROUP BY 
        cd_gender
),
combined_summary AS (
    SELECT 
        a.ca_city,
        a.unique_addresses,
        a.all_street_names,
        a.all_suites,
        a.all_zip_codes,
        c.customer_count,
        c.all_customers
    FROM 
        address_summary a 
    LEFT JOIN 
        customer_summary c ON a.ca_city = c.cd_gender
)
SELECT 
    cs.ca_city,
    cs.unique_addresses,
    cs.all_street_names,
    cs.all_suites,
    cs.all_zip_codes,
    COALESCE(cs.customer_count, 0) AS customer_count,
    COALESCE(cs.all_customers, 'No customers') AS all_customers
FROM 
    combined_summary cs
ORDER BY 
    cs.unique_addresses DESC;
