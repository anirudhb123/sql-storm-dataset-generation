
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Single'
        END AS marital_status,
        COUNT(sr.returned_date_sk) AS total_returns
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_city, ca.ca_state
),
education_summary AS (
    SELECT 
        cd.cd_education_status,
        COUNT(*) AS customer_count,
        AVG(total_returns) AS avg_returns
    FROM 
        customer_info ci
    JOIN 
        customer_demographics cd ON ci.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_education_status
)
SELECT 
    es.cd_education_status,
    es.customer_count,
    es.avg_returns,
    CONCAT(ROUND(es.avg_returns, 2), ' returns on average per customer') AS avg_returns_description
FROM 
    education_summary es
ORDER BY 
    es.customer_count DESC;
