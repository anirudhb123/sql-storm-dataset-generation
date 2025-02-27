
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cad.ca_city,
        cad.ca_state,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ROW_NUMBER() OVER (PARTITION BY cad.ca_city, cad.ca_state ORDER BY c.c_last_name, c.c_first_name) AS rank
    FROM 
        customer c
    JOIN 
        customer_address cad ON c.c_current_addr_sk = cad.ca_address_sk
),
CityCustomerStats AS (
    SELECT 
        ca_city, 
        ca_state,
        COUNT(c_customer_sk) AS customer_count,
        MAX(rank) AS max_rank,
        MIN(rank) AS min_rank,
        AVG(rank) AS avg_rank
    FROM 
        RankedCustomers
    GROUP BY 
        ca_city, ca_state
),
CustomerBenchmark AS (
    SELECT 
        ca_city, 
        ca_state,
        customer_count,
        max_rank,
        min_rank,
        avg_rank,
        CASE 
            WHEN customer_count > 100 THEN 'High'
            WHEN customer_count BETWEEN 51 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS customer_density
    FROM 
        CityCustomerStats
)
SELECT 
    ca_city, 
    ca_state,
    customer_count,
    max_rank,
    min_rank,
    avg_rank,
    customer_density,
    STRING_AGG(full_name, ', ') AS customer_names
FROM 
    CustomerBenchmark
JOIN 
    RankedCustomers rc ON rc.ca_city = CityCustomerStats.ca_city AND rc.ca_state = CityCustomerStats.ca_state
GROUP BY 
    ca_city, ca_state, customer_count, max_rank, min_rank, avg_rank, customer_density
ORDER BY 
    ca_state, ca_city;
