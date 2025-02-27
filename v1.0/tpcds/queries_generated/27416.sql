
WITH address_parts AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        TRIM(BOTH ' ' FROM ca_city) AS city,
        TRIM(BOTH ' ' FROM ca_state) AS state,
        TRIM(BOTH ' ' FROM ca_country) AS country
    FROM 
        customer_address
),
demographic_groups AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
address_overview AS (
    SELECT 
        a.ca_address_sk,
        a.full_address,
        a.city,
        a.state,
        a.country,
        d.cd_gender,
        d.cd_marital_status,
        d.customer_count,
        d.avg_purchase_estimate
    FROM 
        address_parts a
    LEFT JOIN 
        demographic_groups d ON a.city = d.city AND a.state = d.state
)
SELECT 
    ao.city,
    ao.state,
    ao.country,
    COUNT(ao.ca_address_sk) AS total_addresses,
    SUM(ao.customer_count) AS total_customers,
    AVG(ao.avg_purchase_estimate) AS average_purchase_estimate
FROM 
    address_overview ao
WHERE 
    ao.country LIKE 'United%'
GROUP BY 
    ao.city, ao.state, ao.country
ORDER BY 
    total_customers DESC, total_addresses DESC
LIMIT 100;
