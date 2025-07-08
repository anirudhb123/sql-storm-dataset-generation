
WITH processed_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1) AS email_domain,
        LENGTH(c.c_email_address) AS email_length
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        UPPER(cd.cd_gender) = 'F'
        AND cd.cd_purchase_estimate > 500
        AND (ca.ca_state = 'CA' OR ca.ca_state = 'NY')
),
customer_stats AS (
    SELECT 
        full_name,
        COUNT(*) AS total_orders,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        LISTAGG(DISTINCT email_domain, ', ') AS unique_domains,
        MAX(email_length) AS max_email_length
    FROM 
        processed_customers
    GROUP BY 
        full_name
)
SELECT 
    full_name,
    total_orders,
    avg_purchase_estimate,
    unique_domains,
    max_email_length
FROM 
    customer_stats
ORDER BY 
    avg_purchase_estimate DESC
LIMIT 10;
