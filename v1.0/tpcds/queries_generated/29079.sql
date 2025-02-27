
WITH ranked_addresses AS (
    SELECT 
        ca_address_id,
        ca_city,
        ca_state,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS city_rank,
        LENGTH(ca_street_name) AS street_name_length,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LOWER(ca_city) AS lower_city,
        UPPER(ca_country) AS upper_country
    FROM 
        customer_address
),
demographics_with_addresses AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ra.full_address,
        ra.city_rank
    FROM 
        customer_demographics cd
    JOIN 
        customer_address ca ON cd.cd_demo_sk = ca.ca_address_sk
    JOIN 
        ranked_addresses ra ON ra.ca_address_id = ca.ca_address_id
),
filtered_demographics AS (
    SELECT 
        *,
        CASE 
            WHEN cd_gender = 'M' THEN 'Mr.'
            WHEN cd_gender = 'F' THEN 'Ms.'
            ELSE 'Mx.'
        END AS salutation,
        CASE 
            WHEN street_name_length < 30 THEN 'Short Street Name'
            WHEN street_name_length BETWEEN 30 AND 50 THEN 'Medium Street Name'
            ELSE 'Long Street Name'
        END AS street_name_category
    FROM 
        demographics_with_addresses
    WHERE 
        cd_marital_status = 'M'
)
SELECT 
    cd_demo_sk,
    salutation,
    ca_city,
    ca_state,
    upper_country,
    full_address, 
    city_rank,
    street_name_category
FROM 
    filtered_demographics
WHERE 
    lower_city LIKE 'a%' AND city_rank <= 5
ORDER BY 
    ca_city, cd_demo_sk DESC;
