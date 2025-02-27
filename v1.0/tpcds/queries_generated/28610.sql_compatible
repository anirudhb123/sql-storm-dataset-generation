
WITH ProcessedCustomers AS (
    SELECT 
        c.c_customer_sk,
        TRIM(UPPER(c.c_first_name)) AS normalized_first_name,
        CONCAT(LOWER(c.c_last_name), ' (', c.c_customer_id, ')') AS formatted_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        CONCAT(cd.cd_marital_status, ' ', cd.cd_education_status) AS demographic_info,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUBSTRING(c.c_email_address, 1, 20) AS short_email
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregateData AS (
    SELECT 
        normalized_first_name,
        formatted_last_name,
        ca_city,
        ca_state,
        cd_gender,
        demographic_info,
        COUNT(*) AS customer_count,
        STRING_AGG(short_email, ', ') AS email_list
    FROM 
        ProcessedCustomers
    GROUP BY 
        normalized_first_name, 
        formatted_last_name,
        ca_city,
        ca_state,
        cd_gender,
        demographic_info
)
SELECT 
    normalized_first_name,
    formatted_last_name,
    ca_city,
    ca_state,
    cd_gender,
    demographic_info,
    customer_count,
    email_list
FROM 
    AggregateData
WHERE 
    customer_count > 1
ORDER BY 
    customer_count DESC, 
    normalized_first_name;
