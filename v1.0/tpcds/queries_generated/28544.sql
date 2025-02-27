
WITH CustomerAddresses AS (
    SELECT DISTINCT ca.ca_city, 
           ca.ca_state, 
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE ca.ca_city IS NOT NULL AND ca.ca_state IS NOT NULL
),
FrequentCities AS (
    SELECT ca_city, ca_state, COUNT(*) AS customer_count
    FROM CustomerAddresses
    GROUP BY ca_city, ca_state
    HAVING COUNT(*) > 10
),
CityDetails AS (
    SELECT ca.ca_city, ca.ca_state, 
           STRING_AGG(DISTINCT CONCAT(full_name, ': ', ca.ca_zip) ORDER BY full_name) AS customer_details
    FROM CustomerAddresses ca
    JOIN FrequentCities fc ON ca.ca_city = fc.ca_city AND ca.ca_state = fc.ca_state
    GROUP BY ca.ca_city, ca.ca_state
)
SELECT ca_year.d_year,
       fc.ca_city,
       fc.ca_state,
       COUNT(fc.customer_count) AS total_customers,
       MIN(fc.ca_city) AS first_city_name,
       MAX(fc.ca_state) AS last_state_name
FROM date_dim ca_year
JOIN FrequentCities fc ON ca_year.d_year BETWEEN 2021 AND 2023
GROUP BY ca_year.d_year, fc.ca_city, fc.ca_state
ORDER BY ca_year.d_year, fc.ca_city;
