
WITH address_summary AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        STRING_AGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS address_list
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
    GROUP BY 
        ca_city, ca_state
),
customer_details AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ad.ca_city,
        ad.ca_state,
        ad.unique_addresses,
        ad.address_list
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        address_summary ad ON ad.ca_city = (SELECT ca_city FROM customer_address WHERE ca_address_sk = c.c_current_addr_sk)
    WHERE 
        cd.cd_purchase_estimate > 5000
)
SELECT 
    city,
    state,
    COUNT(c_customer_id) AS num_customers,
    STRING_AGG(CONCAT(c_first_name, ' ', c_last_name, ' (', c_customer_id, ')'), ', ') AS customer_names,
    MAX(unique_addresses) AS max_addresses,
    MIN(unique_addresses) AS min_addresses,
    MAX(address_list) AS sample_addresses
FROM 
    customer_details
GROUP BY 
    city, state
ORDER BY 
    num_customers DESC;
