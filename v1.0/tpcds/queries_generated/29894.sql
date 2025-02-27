
WITH CustomerCity AS (
    SELECT DISTINCT 
        ca_city,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        STRING_AGG(CONCAT(c_first_name, ' ', c_last_name), ', ') AS customer_names
    FROM 
        customer_address
    JOIN 
        customer ON ca_address_sk = c_current_addr_sk
    GROUP BY 
        ca_city
),
TopCities AS (
    SELECT 
        ca_city,
        customer_count,
        customer_names,
        ROW_NUMBER() OVER (ORDER BY customer_count DESC) AS city_rank
    FROM 
        CustomerCity
)
SELECT 
    ca_city AS "City",
    customer_count AS "Number of Customers",
    customer_names AS "Customer Names"
FROM 
    TopCities
WHERE 
    city_rank <= 10 
ORDER BY 
    customer_count DESC;
