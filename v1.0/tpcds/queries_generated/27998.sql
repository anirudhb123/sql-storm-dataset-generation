
WITH CustomerAddresses AS (
    SELECT 
        ca.city AS address_city,
        ca.state AS address_state,
        SUM(CASE WHEN cd.gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN cd.gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c.customer_id) AS total_customers
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.city, 
        ca.state
),
AggregatedData AS (
    SELECT 
        address_city,
        address_state,
        female_count,
        male_count,
        avg_purchase_estimate,
        total_customers,
        (female_count + male_count) AS total_gender_count,
        (avg_purchase_estimate / NULLIF(total_gender_count, 0)) AS avg_purchase_per_gender
    FROM 
        CustomerAddresses
)
SELECT 
    address_city,
    address_state,
    total_customers,
    female_count,
    male_count,
    total_gender_count,
    avg_purchase_estimate,
    avg_purchase_per_gender
FROM 
    AggregatedData
WHERE 
    total_customers > 50
ORDER BY 
    total_customers DESC, 
    avg_purchase_estimate DESC;
