
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        REPLACE(CONCAT(c.c_first_name, ' ', c.c_last_name), ' ', '_') AS full_name_underscore,
        CONCAT_WS(', ', ca.ca_city, ca.ca_state, ca.ca_country) AS full_address,
        LENGTH(c.c_email_address) AS email_length
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    COUNT(*) AS total_customers,
    cd.cd_gender,
    cd.cd_marital_status,
    AVG(email_length) AS avg_email_length,
    COUNT(DISTINCT full_name_underscore) AS unique_names,
    STRING_AGG(DISTINCT full_address, '; ' ORDER BY full_address DESC) AS distinct_addresses
FROM 
    CustomerDetails cd
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_customers DESC;
