
WITH AddressAnalytics AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                    THEN CONCAT(' Suite ', ca_suite_number) 
                    ELSE '' END) AS full_address,
        LOWER(ca_city) AS normalized_city,
        CASE 
            WHEN LOWER(ca_state) IN ('ca', 'ny', 'tx') THEN 'High Value State'
            ELSE 'Other State'
        END AS state_category
    FROM customer_address
),
DemographicsAnalytics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CASE 
            WHEN cd_purchase_estimate > 1000 THEN 'High Estimator'
            WHEN cd_purchase_estimate > 500 THEN 'Medium Estimator'
            ELSE 'Low Estimator'
        END AS purchase_bracket
    FROM customer_demographics
),
CustomerAddressJoin AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        d.cd_gender,
        d.purchase_bracket,
        a.normalized_city,
        a.state_category
    FROM customer c
    JOIN AddressAnalytics a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN DemographicsAnalytics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    normalized_city,
    state_category,
    purchase_bracket,
    COUNT(*) AS customer_count,
    STRING_AGG(CONCAT(c_first_name, ' ', c_last_name), ', ') AS customer_names
FROM CustomerAddressJoin
GROUP BY 
    normalized_city, 
    state_category, 
    purchase_bracket
ORDER BY 
    customer_count DESC
LIMIT 10;
