
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        c.c_email_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
filtered_data AS (
    SELECT 
        * 
    FROM 
        customer_data
    WHERE 
        cd_gender = 'M' AND 
        (LOWER(ca_city) LIKE '%spring%' OR LOWER(ca_country) LIKE '%united states%')
),
aggregated_data AS (
    SELECT 
        COUNT(*) AS total_customers,
        COUNT(DISTINCT c_customer_sk) AS distinct_customer_count,
        STRING_AGG(full_name, ', ') AS customer_names
    FROM 
        filtered_data
)
SELECT 
    ad.total_customers,
    ad.distinct_customer_count,
    ad.customer_names,
    STRING_AGG(DISTINCT fd.ca_state, ', ') AS unique_states
FROM 
    aggregated_data ad
JOIN 
    filtered_data fd ON 1=1
GROUP BY 
    ad.total_customers, ad.distinct_customer_count, ad.customer_names;
