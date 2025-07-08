
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS address_rank
    FROM 
        customer_address
),
TopCities AS (
    SELECT 
        ca_city,
        COUNT(*) AS city_count
    FROM 
        RankedAddresses
    GROUP BY 
        ca_city
    HAVING 
        COUNT(*) > 10
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        r.ca_city,
        r.full_address,
        ROW_NUMBER() OVER (PARTITION BY r.ca_city ORDER BY c.c_customer_sk) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        RankedAddresses r ON c.c_current_addr_sk = r.ca_address_sk
    WHERE 
        r.ca_city IN (SELECT ca_city FROM TopCities)
)
SELECT 
    ca_city,
    COUNT(*) AS total_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    LISTAGG(CONCAT(c_first_name, ' ', c_last_name, ' - ', full_address), '; ') WITHIN GROUP (ORDER BY c_first_name) AS customer_details
FROM 
    CustomerStats
JOIN 
    customer_demographics cd ON CustomerStats.c_customer_sk = cd.cd_demo_sk
GROUP BY 
    ca_city
ORDER BY 
    total_customers DESC;
