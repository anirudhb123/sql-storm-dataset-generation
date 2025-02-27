
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city, ca.ca_state ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
customer_string_summary AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(*) AS customer_count,
        STRING_AGG(c.c_first_name || ' ' || c.c_last_name, ', ') AS customer_names
    FROM 
        ranked_customers rc
    JOIN 
        customer_address ca ON rc.c_customer_id = ca.ca_address_id
    WHERE 
        rc.rn <= 5 -- Top 5 customers from each city/state
    GROUP BY 
        ca.ca_city, ca.ca_state
)
SELECT 
    cs.ca_city,
    cs.ca_state,
    cs.customer_count,
    LENGTH(cs.customer_names) AS total_name_length,
    cs.customer_names
FROM 
    customer_string_summary cs
WHERE 
    LENGTH(cs.customer_names) > 50 -- only include summaries with a combined name length greater than 50 characters
ORDER BY 
    cs.ca_state, cs.ca_city;
