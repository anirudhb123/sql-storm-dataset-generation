
WITH address_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(DISTINCT ca_zip) AS unique_zip_codes,
        STRING_AGG(DISTINCT ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT ca_street_type, ', ') AS street_types
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
customer_summary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
combined_summary AS (
    SELECT 
        a.ca_state,
        a.unique_addresses,
        a.unique_zip_codes,
        a.cities,
        a.street_types,
        c.cd_gender,
        c.total_customers,
        c.avg_purchase_estimate,
        c.marital_statuses
    FROM 
        address_summary a
    LEFT JOIN 
        customer_summary c ON c.total_customers > 0
)
SELECT 
    ca_state,
    unique_addresses,
    unique_zip_codes,
    cities,
    street_types,
    SUM(total_customers) OVER () AS total_customers_across_states,
    AVG(avg_purchase_estimate) OVER () AS avg_purchase_across_states
FROM 
    combined_summary
ORDER BY 
    unique_addresses DESC, 
    ca_state;
