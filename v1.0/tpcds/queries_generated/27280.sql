
WITH ranked_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM customer_demographics cd
),
filtered_addresses AS (
    SELECT 
        ca.ca_address_sk,
        LOWER(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_city, ', ', ca.ca_state)) AS full_address,
        LENGTH(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_city, ', ', ca.ca_state)) AS address_length
    FROM customer_address ca
    WHERE ca.ca_city LIKE '%Spring%'
),
top_purchases AS (
    SELECT 
        ca.ca_address_sk,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        f.full_address,
        f.address_length
    FROM ranked_demographics cd
    JOIN filtered_addresses f ON cd.cd_demo_sk = f.ca_address_sk
    WHERE cd.rnk <= 5
)
SELECT 
    t.cd_gender,
    COUNT(*) AS demographic_count,
    SUM(t.cd_purchase_estimate) AS total_estimated_purchases,
    AVG(t.address_length) AS avg_address_length,
    MIN(t.full_address) AS min_address,
    MAX(t.full_address) AS max_address
FROM top_purchases t
GROUP BY t.cd_gender
ORDER BY demographic_count DESC;
