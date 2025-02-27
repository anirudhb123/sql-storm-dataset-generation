
WITH address_analysis AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS address_count,
        MIN(ca_zip) AS min_zip,
        MAX(ca_zip) AS max_zip,
        STRING_AGG(DISTINCT ca_city, ', ') AS unique_cities,
        STRING_AGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), ', ') AS unique_streets
    FROM customer_address
    GROUP BY ca_state
), 
customer_analysis AS (
    SELECT 
        cd.gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.gender
)
SELECT 
    a.ca_state,
    a.address_count,
    a.min_zip,
    a.max_zip,
    a.unique_cities,
    a.unique_streets,
    c.gender,
    c.customer_count,
    c.avg_purchase_estimate
FROM address_analysis a
JOIN customer_analysis c ON (a.address_count > 100 AND c.customer_count > 50)
ORDER BY a.ca_state, c.gender;
