
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_street_number, ca_street_name, ca_city, ca_state, ca_country, 1 as level
    FROM customer_address
    WHERE ca_country IS NOT NULL

    UNION ALL

    SELECT ah.ca_address_sk, ah.ca_address_id, ah.ca_street_number, ah.ca_street_name, ah.ca_city, ah.ca_state, ah.ca_country, ah.level + 1
    FROM customer_address ah
    JOIN address_hierarchy a ON a.ca_address_id = ah.ca_address_id
    WHERE ah.ca_country IS NOT NULL
),
aggregated_data AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        SUM(COALESCE(c.c_birth_year, 0)) AS total_birth_year,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd.cd_credit_rating) AS max_credit_rating,
        MIN(cd.cd_dep_count) AS min_dep_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN address_hierarchy a ON c.c_current_addr_sk = a.ca_address_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COUNT(DISTINCT c.c_customer_sk) DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT 
    a.ca_country,
    ad.cd_gender,
    ad.cd_marital_status,
    ad.num_customers,
    ad.total_birth_year,
    ad.avg_purchase_estimate,
    ad.max_credit_rating,
    ad.min_dep_count,
    CASE 
        WHEN tc.rn IS NOT NULL THEN 'Top'
        ELSE 'Other'
    END AS customer_category
FROM aggregated_data ad
JOIN address_hierarchy a ON ad.cd_gender = a.ca_city
LEFT JOIN top_customers tc ON ad.cd_gender = tc.cd_gender AND ad.cd_marital_status = tc.cd_marital_status
WHERE a.ca_state = 'CA' AND ad.avg_purchase_estimate > 1000
ORDER BY a.ca_country, ad.cd_gender
