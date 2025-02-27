
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY ca.ca_state) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
string_processing_benchmark AS (
    SELECT 
        city_rank,
        COUNT(*) AS customer_count,
        STRING_AGG(CONCAT(c_first_name, ' ', c_last_name), '; ') AS customer_names,
        SUBSTRING(STRING_AGG(CONCAT(c_first_name, ' ', c_last_name), '; '), 1, 100) AS truncated_names,
        LENGTH(SUBSTRING(STRING_AGG(CONCAT(c_first_name, ' ', c_last_name), '; '), 1, 100)) AS name_length
    FROM 
        ranked_customers
    WHERE 
        cd_gender = 'F' AND 
        cd_marital_status = 'M'
    GROUP BY 
        city_rank
)
SELECT 
    city_rank,
    customer_count,
    customer_names,
    truncated_names,
    name_length
FROM 
    string_processing_benchmark
WHERE 
    customer_count > 0
ORDER BY 
    city_rank;
