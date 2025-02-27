
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn,
        COALESCE(ca.ca_city, 'Unknown') AS city,
        COALESCE(ca.ca_state, 'Unknown') AS state,
        COALESCE(ca.ca_country, 'Unknown') AS country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
top_customers AS (
    SELECT 
        c_customer_id,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        city,
        state,
        country
    FROM ranked_customers
    WHERE rn <= 5
)
SELECT 
    tc.cd_gender,
    tc.city,
    tc.state,
    COUNT(tc.c_customer_id) AS total_customers,
    STRING_AGG(CONCAT(tc.c_first_name, ' ', tc.c_last_name) ORDER BY tc.c_first_name) AS customer_names
FROM top_customers tc
GROUP BY 
    tc.cd_gender,
    tc.city,
    tc.state
ORDER BY 
    tc.cd_gender,
    total_customers DESC;
