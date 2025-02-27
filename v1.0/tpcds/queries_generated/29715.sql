
WITH AddressStatistics AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(CASE WHEN ca_street_type IS NOT NULL THEN 1 ELSE 0 END) AS type_count,
        ARRAY_AGG(DISTINCT ca_city) AS unique_cities
    FROM customer_address
    GROUP BY ca_state
),
CustomerData AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        AVG(cd_dep_count) AS avg_dependents
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd_gender
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.avg_street_name_length,
    a.type_count,
    a.unique_cities,
    c.cd_gender,
    c.total_customers,
    c.avg_purchase_estimate,
    c.avg_dependents
FROM AddressStatistics a
FULL OUTER JOIN CustomerData c ON a.ca_state = (
    SELECT ca_state
    FROM customer_address
    WHERE ca_address_sk = (
        SELECT c_current_addr_sk
        FROM customer
        WHERE c_current_cdemo_sk = (
            SELECT cd_demo_sk
            FROM customer_demographics
            WHERE cd_gender = c.cd_gender
            LIMIT 1
        )
        LIMIT 1
    )
)
ORDER BY a.ca_state, c.cd_gender;
