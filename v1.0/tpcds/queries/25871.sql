
WITH processed_data AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        SUM(cd_purchase_estimate) AS total_estimated_spending
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca_city, 
        ca_state, 
        full_address, 
        cd_gender, 
        cd_marital_status
),
string_aggregated AS (
    SELECT 
        ca_city,
        ca_state,
        cd_gender,
        cd_marital_status,
        COUNT(customer_count) AS total_customers,
        SUM(total_estimated_spending) AS total_spending,
        STRING_AGG(full_address, ', ') AS all_addresses
    FROM 
        processed_data
    GROUP BY 
        ca_city, ca_state, cd_gender, cd_marital_status
)
SELECT 
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    total_customers,
    total_spending,
    LENGTH(all_addresses) AS total_address_length,
    SUBSTRING(all_addresses, 1, 100) AS sample_addresses
FROM 
    string_aggregated
ORDER BY 
    total_spending DESC, 
    ca_city, 
    ca_state;
