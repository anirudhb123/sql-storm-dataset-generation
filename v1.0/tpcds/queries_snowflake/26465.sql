
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Mr. ' || c.c_first_name
            WHEN cd.cd_gender = 'F' THEN 'Ms. ' || c.c_first_name
            ELSE c.c_first_name
        END AS salutation,
        LENGTH(c.c_email_address) AS email_length,
        LOWER(c.c_email_address) AS lowercase_email
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state = 'CA'
        AND cd.cd_purchase_estimate > 1000
),
aggregated_data AS (
    SELECT 
        full_name,
        COUNT(*) AS num_customers,
        MIN(email_length) AS min_email_length,
        MAX(email_length) AS max_email_length,
        AVG(email_length) AS avg_email_length
    FROM 
        customer_data
    GROUP BY 
        full_name
)
SELECT 
    a.full_name,
    a.num_customers,
    a.min_email_length,
    a.max_email_length,
    a.avg_email_length,
    LISTAGG(DISTINCT cd.ca_city, ', ') AS unique_cities,
    LISTAGG(DISTINCT cd.ca_state, ', ') AS unique_states
FROM 
    aggregated_data a
JOIN 
    customer_data cd ON a.full_name = cd.full_name
GROUP BY 
    a.full_name, a.num_customers, a.min_email_length, a.max_email_length, a.avg_email_length
ORDER BY 
    a.num_customers DESC;
