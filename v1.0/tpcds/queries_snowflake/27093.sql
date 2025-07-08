
WITH processed_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1) AS email_domain,
        LOWER(TRIM(CONCAT(c.c_first_name, c.c_last_name))) AS normalized_name
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_country = 'USA' 
        AND cd.cd_purchase_estimate > 10000 
        AND cd.cd_gender IN ('M', 'F')
),
aggregated_data AS (
    SELECT 
        email_domain,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        LISTAGG(DISTINCT CONCAT(full_name, '(', cd_gender, ')'), '; ') WITHIN GROUP (ORDER BY full_name) AS customer_names
    FROM 
        processed_data
    GROUP BY 
        email_domain
)
SELECT 
    email_domain,
    customer_count,
    avg_purchase_estimate,
    customer_names
FROM 
    aggregated_data
ORDER BY 
    customer_count DESC
LIMIT 10;
