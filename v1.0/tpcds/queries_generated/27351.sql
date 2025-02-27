
WITH address_parts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
demographic_summary AS (
    SELECT 
        cd_demo_sk,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependents
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk
),
address_demographics AS (
    SELECT 
        a.ca_address_sk,
        a.full_address,
        a.ca_city,
        a.ca_state,
        d.customer_count,
        d.avg_purchase_estimate,
        d.max_dependents
    FROM 
        address_parts a
    JOIN 
        demographic_summary d ON d.customer_count > 1
)
SELECT 
    CONCAT(full_address, ', ', ca_city, ', ', ca_state, ' ', ca_zip, ' (', ca_country, ')') AS complete_address,
    customer_count,
    avg_purchase_estimate,
    max_dependents
FROM 
    address_demographics
WHERE 
    ca_state = 'CA'
ORDER BY 
    customer_count DESC, avg_purchase_estimate DESC
LIMIT 10;
