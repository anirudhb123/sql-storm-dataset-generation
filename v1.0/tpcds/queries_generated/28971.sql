
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_zip) AS city_rank
    FROM 
        customer_address
),
FilteredAddresses AS (
    SELECT 
        full_address,
        ca_city,
        ca_state
    FROM 
        RankedAddresses
    WHERE 
        city_rank <= 5
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.city,
        ca.state,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Mr. ' || c.c_first_name
            WHEN cd.cd_gender = 'F' THEN 'Ms. ' || c.c_first_name
            ELSE c.c_first_name 
        END AS salutation
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ci.salutation,
    ci.full_name,
    ci.city,
    ci.state,
    fa.full_address
FROM 
    CustomerInfo AS ci
JOIN 
    FilteredAddresses AS fa ON ci.city = fa.ca_city AND ci.state = fa.ca_state
ORDER BY 
    ci.city, ci.full_name;
