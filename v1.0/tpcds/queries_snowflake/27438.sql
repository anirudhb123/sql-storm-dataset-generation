
WITH address_info AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        ARRAY_AGG(DISTINCT ca_street_name) AS unique_streets
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
customer_info AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(c_customer_sk) AS customer_count,
        ARRAY_AGG(DISTINCT c_first_name || ' ' || c_last_name) AS customer_names
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    ai.ca_city,
    ai.ca_state,
    ai.address_count,
    unique_streets,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.customer_count,
    customer_names
FROM 
    address_info ai
JOIN 
    customer_info ci ON ai.ca_state = ci.cd_gender
WHERE 
    ai.address_count > 5 AND 
    ci.customer_count > 10
ORDER BY 
    ai.ca_city, ci.cd_marital_status;
