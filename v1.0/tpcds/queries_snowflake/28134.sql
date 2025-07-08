
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        LOWER(c.c_first_name) AS first_name,
        LOWER(c.c_last_name) AS last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_id) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
gender_counts AS (
    SELECT 
        cd.cd_gender,
        COUNT(*) AS gender_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
address_summary AS (
    SELECT 
        ca.ca_state,
        COUNT(*) AS address_count,
        ARRAY_AGG(DISTINCT ca.ca_city) AS unique_cities
    FROM 
        customer_address ca
    GROUP BY 
        ca.ca_state
),
final_summary AS (
    SELECT 
        rc.c_customer_id,
        rc.first_name,
        rc.last_name,
        rc.cd_gender,
        rc.gender_rank,
        gc.gender_count,
        asu.address_count,
        LISTAGG(DISTINCT ca.ca_city, ', ') AS unique_cities
    FROM 
        ranked_customers rc
    JOIN 
        gender_counts gc ON rc.cd_gender = gc.cd_gender
    JOIN 
        address_summary asu ON TRUE
    GROUP BY 
        rc.c_customer_id, rc.first_name, rc.last_name, rc.cd_gender, rc.gender_rank, gc.gender_count, asu.address_count
)
SELECT 
    f.c_customer_id,
    f.first_name,
    f.last_name,
    f.cd_gender,
    f.gender_rank,
    f.gender_count,
    f.address_count,
    f.unique_cities,
    CONCAT(f.first_name, ' ', f.last_name) AS full_name,
    LENGTH(CONCAT(f.first_name, ' ', f.last_name)) AS full_name_length
FROM 
    final_summary f
WHERE 
    f.gender_rank <= 5
ORDER BY 
    f.gender_count DESC, f.c_customer_id;
