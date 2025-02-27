
WITH aggregated_data AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(COALESCE(c.c_birth_day, 0) + COALESCE(c.c_birth_month, 0) + COALESCE(c.c_birth_year, 0)) AS total_birth_info,
        STRING_AGG(DISTINCT cd.cd_gender, ', ') AS gender_distribution,
        STRING_AGG(DISTINCT cd.cd_marital_status, ', ') AS marital_status_distribution
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.ca_city, ca.ca_state
),
ranked_data AS (
    SELECT 
        city,
        state,
        total_customers,
        total_birth_info,
        gender_distribution,
        marital_status_distribution,
        RANK() OVER (ORDER BY total_customers DESC) AS customer_rank
    FROM 
        aggregated_data
)
SELECT 
    city,
    state,
    total_customers,
    total_birth_info,
    gender_distribution,
    marital_status_distribution,
    customer_rank
FROM 
    ranked_data
WHERE 
    customer_rank <= 10
ORDER BY 
    customer_rank;
