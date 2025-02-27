
WITH normalized_addresses AS (
    SELECT 
        DISTINCT TRIM(UPPER(ca_street_name)) AS normalized_street_name,
        TRIM(UPPER(ca_city)) AS normalized_city,
        TRIM(UPPER(ca_state)) AS normalized_state,
        TRIM(UPPER(ca_zip)) AS normalized_zip
    FROM 
        customer_address
), demographic_stats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependents
    FROM 
        customer_demographics
    JOIN 
        customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
), address_demo AS (
    SELECT 
        na.normalized_street_name,
        na.normalized_city,
        na.normalized_state,
        na.normalized_zip,
        ds.cd_gender,
        ds.cd_marital_status,
        ds.customer_count,
        ds.avg_purchase_estimate,
        ds.max_dependents
    FROM 
        normalized_addresses na
    LEFT JOIN 
        demographic_stats ds ON na.normalized_city = ds.normalized_city AND na.normalized_state = ds.normalized_state
)
SELECT 
    normalized_street_name,
    normalized_city,
    normalized_state,
    normalized_zip,
    COALESCE(SUM(customer_count), 0) AS total_customers,
    AVG(avg_purchase_estimate) AS average_purchase_estimate,
    MAX(max_dependents) AS max_dependents
FROM 
    address_demo
GROUP BY 
    normalized_street_name, normalized_city, normalized_state, normalized_zip
ORDER BY 
    total_customers DESC
LIMIT 100;
