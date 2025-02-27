
WITH CustomerAddressDetails AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        LENGTH(ca.ca_street_name) AS street_name_length,
        UPPER(ca.ca_street_name) AS upper_street_name,
        LOWER(ca.ca_street_name) AS lower_street_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregatedData AS (
    SELECT 
        ca.city AS city,
        ca.state AS state,
        ca.country AS country,
        cd.gender AS gender,
        COUNT(*) AS total_customers,
        AVG(street_name_length) AS avg_street_name_length,
        STRING_AGG(upper_street_name, ', ') AS upper_street_names,
        STRING_AGG(lower_street_name, ', ') AS lower_street_names,
        COUNT(DISTINCT full_address) AS unique_full_addresses
    FROM CustomerAddressDetails ca 
    GROUP BY ca.city, ca.state, ca.country, cd.gender
)
SELECT 
    city, 
    state, 
    country, 
    gender, 
    total_customers,
    avg_street_name_length,
    unique_full_addresses,
    TRIM(BOTH ',' FROM upper_street_names) AS concatenated_upper_street_names,
    TRIM(BOTH ',' FROM lower_street_names) AS concatenated_lower_street_names
FROM AggregatedData
WHERE total_customers > 10
ORDER BY city, state;
