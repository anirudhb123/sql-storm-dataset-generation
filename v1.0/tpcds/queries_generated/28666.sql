
WITH CustomerData AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_last_name, c.c_first_name) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_marital_status = 'M' AND 
        cd.cd_gender = 'F' AND 
        LENGTH(c.c_first_name) > 3
),
AggregateData AS (
    SELECT 
        ca.ca_city,
        COUNT(*) AS total_customers,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        AVG(LENGTH(c.c_first_name)) AS avg_first_name_length,
        MIN(cd.cd_dep_count) AS min_dependents
    FROM 
        CustomerData cd
    JOIN 
        customer c ON cd.c_first_name = c.c_first_name AND cd.c_last_name = c.c_last_name
    GROUP BY 
        ca.ca_city
)
SELECT 
    ad.ca_city,
    ad.total_customers,
    ad.max_purchase_estimate,
    ad.avg_first_name_length,
    ad.min_dependents,
    STRING_AGG(CONCAT(c.c_first_name, ' ', c.c_last_name) ORDER BY c.c_last_name) AS customer_names
FROM 
    AggregateData ad
JOIN 
    customer c ON c.c_current_cdemo_sk IN (SELECT cd.cd_demo_sk FROM customer_demographics cd WHERE cd.cd_marital_status = 'M' AND cd.cd_gender = 'F')
GROUP BY 
    ad.ca_city, ad.total_customers, ad.max_purchase_estimate, ad.avg_first_name_length, ad.min_dependents
ORDER BY 
    ad.total_customers DESC, ad.ca_city;
