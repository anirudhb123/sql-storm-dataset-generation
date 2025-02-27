
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        TRIM(UPPER(ca_country)) AS normalized_country
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND 
        ca_state IS NOT NULL AND 
        ca_zip IS NOT NULL
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    pa.full_address,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    CONCAT(cd.cd_gender, '-', cd.cd_marital_status, '-', cd.cd_education_status) AS demographic_category,
    COUNT(*) OVER (PARTITION BY pa.normalized_country ORDER BY pa.full_address) AS address_rank
FROM 
    processed_addresses pa
JOIN 
    customer_details cd ON cd.c_customer_sk IN (
        SELECT 
            DISTINCT c_customer_sk 
        FROM 
            store_sales 
        WHERE 
            ss_sold_date_sk IN (
                SELECT 
                    d_date_sk 
                FROM 
                    date_dim 
                WHERE 
                    d_year = 2023 AND d_current_year = 'Y'
            )
    )
WHERE 
    pa.full_address LIKE '%Street%'
ORDER BY 
    pa.normalized_country, 
    address_rank;
