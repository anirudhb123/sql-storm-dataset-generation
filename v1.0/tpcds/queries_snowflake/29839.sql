
WITH 
    CustomerDetails AS (
        SELECT 
            c.c_customer_sk,
            CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
            cd.cd_gender,
            cd.cd_marital_status,
            cd.cd_education_status,
            ca.ca_city,
            ca.ca_state,
            ca.ca_zip,
            CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
        FROM 
            customer c
        JOIN 
            customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN 
            customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    ),
    AddressAnalytics AS (
        SELECT 
            ca_state,
            COUNT(*) AS customer_count,
            LISTAGG(DISTINCT full_address, '; ') AS unique_addresses
        FROM 
            CustomerDetails
        GROUP BY 
            ca_state
    ),
    EducationStatistics AS (
        SELECT 
            cd_education_status,
            COUNT(c_customer_sk) AS education_count,
            AVG(cd_purchase_estimate) AS avg_purchase_estimate
        FROM 
            customer_demographics cd
        JOIN 
            customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
        GROUP BY 
            cd_education_status
    )
SELECT 
    aa.ca_state,
    aa.customer_count,
    aa.unique_addresses,
    es.cd_education_status,
    es.education_count,
    es.avg_purchase_estimate
FROM 
    AddressAnalytics aa
JOIN 
    EducationStatistics es ON aa.customer_count > 100
ORDER BY 
    aa.customer_count DESC, es.education_count DESC;
