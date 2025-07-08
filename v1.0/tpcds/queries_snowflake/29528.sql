
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_last_name, c.c_first_name) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'M' AND 
        cd.cd_marital_status = 'S' AND 
        (cd.cd_education_status ILIKE '%Bachelor%'
         OR cd.cd_education_status ILIKE '%Master%')
),
customer_summary AS (
    SELECT 
        city_rank,
        COUNT(*) AS customer_count,
        LISTAGG(c_customer_id, ', ') AS customer_ids,
        LISTAGG(c_first_name || ' ' || c_last_name, ', ') AS customer_names
    FROM 
        ranked_customers
    WHERE 
        city_rank <= 5
    GROUP BY 
        city_rank
)
SELECT 
    city_rank,
    customer_count,
    customer_ids,
    customer_names
FROM 
    customer_summary
ORDER BY 
    city_rank;
