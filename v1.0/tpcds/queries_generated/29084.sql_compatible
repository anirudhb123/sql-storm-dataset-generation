
WITH RankedAddresses AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_street_name, 
        ca.ca_city, 
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY LENGTH(ca.ca_street_name) DESC) as rn
    FROM 
        customer_address ca 
    WHERE 
        ca.ca_state = 'CA'
),
StreetStats AS (
    SELECT 
        ca_city,
        COUNT(*) as total_streets,
        AVG(LENGTH(ca_street_name)) as average_length,
        MAX(LENGTH(ca_street_name)) as max_length
    FROM 
        RankedAddresses
    WHERE 
        rn <= 5
    GROUP BY 
        ca_city
),
CustomerStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) as total_customers,
        SUM(cd.cd_purchase_estimate) as total_estimate,
        AVG(cd.cd_dep_count) as average_dependent_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    s.ca_city, 
    s.total_streets, 
    s.average_length, 
    s.max_length, 
    cs.cd_gender, 
    cs.total_customers, 
    cs.total_estimate, 
    cs.average_dependent_count
FROM 
    StreetStats s
LEFT JOIN 
    CustomerStats cs ON s.ca_city = (SELECT ca.ca_city FROM customer_address ca WHERE ca.ca_address_sk = s.ca_address_sk LIMIT 1)
ORDER BY 
    s.total_streets DESC, cs.total_customers DESC;
