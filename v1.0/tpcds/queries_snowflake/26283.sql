
WITH AddressDetails AS (
    SELECT 
        ca_state,
        ca_city,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        LISTAGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), ', ') WITHIN GROUP (ORDER BY c_first_name, c_last_name) AS customer_names
    FROM 
        customer_address a
    JOIN 
        customer c ON a.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca_state, ca_city
),
FrequentCities AS (
    SELECT 
        ca_state,
        ca_city,
        customer_count,
        customer_names,
        RANK() OVER (PARTITION BY ca_state ORDER BY customer_count DESC) AS city_rank
    FROM 
        AddressDetails
)
SELECT 
    ca_state,
    ca_city,
    customer_count,
    customer_names,
    CASE 
        WHEN city_rank = 1 THEN 'Most Popular City'
        WHEN city_rank <= 3 THEN 'Top Cities'
        ELSE 'Other Cities'
    END AS popularity_category
FROM 
    FrequentCities
WHERE 
    customer_count > 10
ORDER BY 
    ca_state, city_rank;
