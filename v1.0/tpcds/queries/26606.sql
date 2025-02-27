
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS birth_date,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        JOIN date_dim d ON c.c_birth_day = d.d_dom AND c.c_birth_month = d.d_moy AND c.c_birth_year = d.d_year
)
SELECT 
    full_name,
    COUNT(*) AS transaction_count,
    STRING_AGG(DISTINCT ca_city || ', ' || ca_state, '; ') AS locations,
    MAX(birth_date) AS latest_birth_date,
    CASE 
        WHEN cd_gender = 'M' THEN 'Male'
        WHEN cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender
FROM 
    customer_info
GROUP BY 
    full_name, cd_gender
HAVING 
    COUNT(*) > 1
ORDER BY 
    transaction_count DESC
LIMIT 100;
