
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        LISTAGG(cd.cd_education_status, ', ') WITHIN GROUP (ORDER BY cd.cd_education_status) AS education_statuses,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
        SUM(s.ss_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, ca.ca_city, ca.ca_state
),
StringProcessed AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        education_statuses,
        ca_city,
        ca_state,
        total_sales,
        total_net_profit,
        LENGTH(full_name) AS name_length,
        UPPER(full_name) AS name_uppercase,
        LOWER(full_name) AS name_lowercase,
        REPLACE(full_name, ' ', '-') AS name_hyphenated
    FROM 
        RankedCustomers 
    WHERE 
        total_sales > 0
)
SELECT 
    *
FROM 
    StringProcessed
ORDER BY 
    total_net_profit DESC
LIMIT 10;
