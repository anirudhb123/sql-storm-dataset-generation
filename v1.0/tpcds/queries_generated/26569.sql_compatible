
WITH address_stats AS (
    SELECT 
        ca_country,
        COUNT(*) AS address_count,
        STRING_AGG(ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT ca_street_type, ', ') AS street_types,
        STRING_AGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name), '; ') AS full_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_country
),
customer_states AS (
    SELECT 
        c.c_country AS country,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customers
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_country
),
combined_stats AS (
    SELECT 
        as.ca_country,
        as.address_count,
        as.cities,
        cs.customer_count,
        cs.customers
    FROM 
        address_stats as
    LEFT JOIN 
        customer_states cs ON as.ca_country = cs.country
)
SELECT 
    cs.ca_country,
    cs.address_count,
    cs.cities,
    COALESCE(cs.customer_count, 0) AS customer_count,
    COALESCE(cs.customers, 'No customers') AS customers
FROM 
    combined_stats cs
ORDER BY 
    cs.address_count DESC, 
    cs.customer_count DESC;
