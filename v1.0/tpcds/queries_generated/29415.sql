
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
address_stats AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(*) AS customer_count,
        STRING_AGG(DISTINCT ca.ca_country) AS unique_countries,
        AVG(cd.cd_dep_count) AS avg_dependents
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY ca.ca_city, ca.ca_state
),
top_cities AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        customer_count,
        unique_countries,
        avg_dependents,
        RANK() OVER (ORDER BY customer_count DESC) AS city_rank
    FROM address_stats ca
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    tc.customer_count,
    tc.unique_countries,
    tc.avg_dependents
FROM customer_info ci
JOIN top_cities tc ON ci.ca_city = tc.ca_city AND ci.ca_state = tc.ca_state
WHERE tc.city_rank <= 5
ORDER BY ci.full_name;
