
WITH AddressCounts AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), ', ') AS full_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
Demographics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        STRING_AGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), ', ') AS customer_names
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.address_count,
    a.full_addresses,
    d.cd_gender,
    d.customer_count,
    d.customer_names
FROM 
    AddressCounts AS a
JOIN 
    Demographics AS d ON d.customer_count > 0
ORDER BY 
    a.ca_state, a.ca_city, d.cd_gender;
