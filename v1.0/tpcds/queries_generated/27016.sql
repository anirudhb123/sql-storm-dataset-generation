
WITH processed_customer_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(CAST(CAST(c.c_birth_month AS VARCHAR) + '/' + CAST(c.c_birth_day AS VARCHAR) + '/' + CAST(c.c_birth_year AS VARCHAR) AS DATE), DATE '1900-01-01') AS DATE) AS birth_date,
        ca.ca_city,
        ca.ca_state,
        SUBSTRING(ca.ca_zip FROM 1 FOR 5) AS short_zip,
        LENGTH(ca.ca_street_name) AS street_name_length,
        UPPER(ca.ca_country) AS normalized_country
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
),
ranked_data AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY cd_purchase_estimate DESC) AS state_rank
    FROM 
        processed_customer_data
)
SELECT 
    full_name,
    cd_gender,
    birth_date,
    ca_city,
    ca_state,
    short_zip,
    street_name_length,
    normalized_country
FROM 
    ranked_data
WHERE 
    state_rank <= 10
ORDER BY 
    ca_state, cd_purchase_estimate DESC;
