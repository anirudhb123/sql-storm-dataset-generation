
WITH processed_addresses AS (
    SELECT
        ca_address_sk,
        UPPER(ca_city) AS city,
        LOWER(ca_street_name) AS street_name,
        CONCAT(ca_street_number, ' ', ca_street_type) AS full_address,
        ca_zip
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
),
customer_stats AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_year AS birth_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.city,
        ca.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        processed_addresses ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON c.c_birth_year = d.d_year
    WHERE 
        cd.cd_purchase_estimate > 1000
)
SELECT
    cs.full_name,
    COUNT(DISTINCT cs.city) AS distinct_cities,
    AVG(cs.cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(cs.full_address, ', ') AS addresses
FROM 
    customer_stats cs
GROUP BY 
    cs.full_name
ORDER BY 
    avg_purchase_estimate DESC
LIMIT 10;
