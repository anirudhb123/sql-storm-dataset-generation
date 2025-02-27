
WITH Address_Analysis AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(*) AS total_addresses,
        UPPER(ca_street_name) AS upper_street_name,
        LOWER(ca_street_name) AS lower_street_name,
        LENGTH(ca_street_name) AS street_name_length
    FROM customer_address
    GROUP BY ca_city, ca_state
),
Demographic_Analysis AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        SUM(cd_dep_count) AS total_dependents,
        SUM(cd_dep_employed_count) AS employed_dependents,
        SUM(cd_dep_college_count) AS college_dependents,
        COUNT(DISTINCT c_customer_id) AS unique_customers
    FROM customer_demographics
    JOIN customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY cd_gender
),
Benchmarking AS (
    SELECT 
        a.ca_city,
        a.ca_state,
        a.unique_addresses,
        a.total_addresses,
        d.cd_gender,
        d.total_customers,
        d.total_dependents,
        d.employed_dependents,
        d.college_dependents,
        a.street_name_length
    FROM Address_Analysis a
    LEFT JOIN Demographic_Analysis d ON a.ca_state = d.cd_gender
)
SELECT 
    ca_city,
    ca_state,
    SUM(unique_addresses) AS total_unique_addresses,
    SUM(total_addresses) AS total_addresses_count,
    SUM(total_customers) AS total_customers_count,
    SUM(total_dependents) AS total_dependents,
    AVG(street_name_length) AS avg_street_name_length
FROM Benchmarking
GROUP BY ca_city, ca_state
ORDER BY total_unique_addresses DESC;
