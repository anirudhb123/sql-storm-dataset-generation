
WITH processed_customers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        CASE
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Unknown'
        END AS gender,
        STRING_AGG(DISTINCT cd.cd_marital_status ORDER BY cd.cd_marital_status) AS martial_statuses
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, cd.cd_gender
),
date_filter AS (
    SELECT 
        DISTINCT d.d_date_sk
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN '2022-01-01' AND '2022-12-31'
)
SELECT 
    pc.full_name, 
    pc.ca_city, 
    pc.gender, 
    pc.martial_statuses, 
    df.d_date_sk
FROM 
    processed_customers pc
CROSS JOIN 
    date_filter df
WHERE 
    pc.gender != 'Unknown'
ORDER BY 
    pc.full_name, df.d_date_sk;
