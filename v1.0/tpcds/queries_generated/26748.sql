
WITH CustomerCityStats AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        COUNT(DISTINCT c_current_addr_sk) AS total_addresses,
        STRING_AGG(DISTINCT cd_gender, ', ') AS unique_genders,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS unique_marital_status
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca_city
),
CityRanking AS (
    SELECT 
        ca_city,
        total_customers,
        total_addresses,
        unique_genders,
        unique_marital_status,
        DENSE_RANK() OVER (ORDER BY total_customers DESC) AS customer_rank
    FROM 
        CustomerCityStats
)
SELECT 
    *,
    CASE 
        WHEN total_customers > 1000 THEN 'High'
        WHEN total_customers BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low' 
    END AS customer_band
FROM 
    CityRanking
WHERE 
    total_addresses > 0
ORDER BY 
    customer_rank;
