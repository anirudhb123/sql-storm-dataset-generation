
WITH CustomerAddressSummary AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        STRING_AGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), ', ') AS customer_names
    FROM 
        customer_address AS ca
    JOIN 
        customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca_city, ca_state
),
AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        MAX(customer_count) AS max_customers,
        MIN(customer_count) AS min_customers,
        MAX(LENGTH(customer_names)) AS max_name_length
    FROM 
        CustomerAddressSummary
    GROUP BY 
        ca_state
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.unique_cities,
    a.max_customers,
    a.min_customers,
    a.max_name_length,
    (SELECT AVG(customer_count) FROM CustomerAddressSummary WHERE ca_state = a.ca_state) AS avg_customers
FROM 
    AddressStats AS a
ORDER BY 
    a.max_customers DESC;
