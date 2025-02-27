
WITH CustomerData AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
FilteredCustomers AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_country) AS full_address
    FROM 
        CustomerData
    WHERE 
        cd_gender = 'F'
        AND cd_marital_status = 'M'
        AND cd_education_status LIKE '%Graduate%'
),
AggregateData AS (
    SELECT 
        cd_education_status,
        COUNT(*) AS total_customers,
        STRING_AGG(full_name, '; ') AS customer_names
    FROM 
        FilteredCustomers
    GROUP BY 
        cd_education_status
)
SELECT 
    ad.cd_education_status,
    ad.total_customers,
    ad.customer_names,
    CHAR_LENGTH(ad.customer_names) AS names_length,
    LENGTH(ad.customer_names) - LENGTH(REPLACE(ad.customer_names, ';', '')) + 1 AS name_count
FROM 
    AggregateData ad
ORDER BY 
    ad.total_customers DESC;
