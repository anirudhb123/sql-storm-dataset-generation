
WITH string_benchmark AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        STRING_AGG(DISTINCT ca.ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT ca.ca_state, ', ') AS states,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count,
        COUNT(DISTINCT cd.cd_demo_sk) AS demographic_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) > 15
)
SELECT 
    COUNT(*) AS total_long_names,
    AVG(LENGTH(full_name)) AS avg_name_length,
    MAX(LENGTH(full_name)) AS max_name_length,
    MIN(LENGTH(full_name)) AS min_name_length
FROM 
    string_benchmark;
