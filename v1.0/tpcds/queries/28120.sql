
WITH address_counts AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT ca_address_id) AS address_count,
        COUNT(DISTINCT ca_zip) AS unique_zip_count
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
customer_details AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        ca.ca_city,
        ac.address_count,
        ac.unique_zip_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        address_counts ac ON ca.ca_city = ac.ca_city
)
SELECT 
    cd.ca_city,
    COUNT(*) AS total_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    STRING_AGG(DISTINCT cd.cd_marital_status, ', ') AS marital_statuses
FROM 
    customer_details cd
GROUP BY 
    cd.ca_city
ORDER BY 
    total_customers DESC;
