
WITH concatenated_data AS (
    SELECT 
        c.c_first_name || ' ' || c.c_last_name AS customer_name,
        CONCAT_WS(', ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_suite_number, ca.ca_city, ca.ca_state, ca.ca_zip) AS full_address,
        DENSE_RANK() OVER (PARTITION BY ca.ca_state ORDER BY c.c_first_name) AS rank_in_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_city IS NOT NULL
),
filtered_data AS (
    SELECT 
        DISTINCT customer_name,
        full_address,
        rank_in_state,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        concatenated_data
    WHERE 
        cd_gender = 'F' AND 
        cd_marital_status = 'M' AND 
        cd_purchase_estimate > 500
)
SELECT 
    rank_in_state,
    COUNT(*) AS customer_count,
    AVG(cd_purchase_estimate) AS average_purchase_estimate,
    STRING_AGG(full_address, '; ') AS addresses
FROM 
    filtered_data
GROUP BY 
    rank_in_state
ORDER BY 
    rank_in_state;
