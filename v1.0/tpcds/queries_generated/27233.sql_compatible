
WITH CustomerWithDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_email_address) AS email_length
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
),
AggregatedMetrics AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(email_length) AS avg_email_length,
        STRING_AGG(full_name, ', ') AS customer_names
    FROM 
        CustomerWithDetails c
    JOIN 
        customer_address ca ON c.c_customer_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    cm.ca_state,
    cm.customer_count,
    cm.avg_email_length,
    cm.customer_names,
    CHAR_LENGTH(cm.customer_names) AS names_length
FROM 
    AggregatedMetrics cm
WHERE 
    cm.customer_count > 10
ORDER BY 
    cm.customer_count DESC;
