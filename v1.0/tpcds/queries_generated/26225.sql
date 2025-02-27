
WITH CustomerAddressDetails AS (
    SELECT 
        ca.city AS customer_city,
        ca.state AS customer_state,
        ca.country AS customer_country,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cd.demo_sk,
        cd.marital_status,
        cd.education_status
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
Stats AS (
    SELECT 
        customer_city, 
        customer_state, 
        customer_country,
        COUNT(*) AS num_customers,
        AVG(LENGTH(full_name)) AS avg_name_length,
        COUNT(DISTINCT demo_sk) AS unique_demographics
    FROM CustomerAddressDetails
    GROUP BY customer_city, customer_state, customer_country
),
MostCommon AS (
    SELECT 
        customer_city, 
        customer_state, 
        customer_country,
        ROW_NUMBER() OVER (PARTITION BY customer_state ORDER BY num_customers DESC) AS rank
    FROM Stats
)
SELECT 
    city, 
    state, 
    country,
    num_customers,
    avg_name_length,
    unique_demographics
FROM Stats
JOIN MostCommon mc ON Stats.customer_city = mc.customer_city 
                  AND Stats.customer_state = mc.customer_state 
                  AND Stats.customer_country = mc.customer_country
WHERE mc.rank <= 3
ORDER BY customer_state, num_customers DESC;
