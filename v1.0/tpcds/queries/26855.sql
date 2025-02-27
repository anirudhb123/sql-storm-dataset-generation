
WITH RankedCustomers AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year ASC) AS rn
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
    AND 
        cd.cd_education_status IN ('Bachelors', 'Masters')
),
AddressSummary AS (
    SELECT 
        full_address,
        COUNT(*) AS customer_count,
        STRING_AGG(full_name, ', ') AS customer_names
    FROM 
        RankedCustomers
    WHERE 
        rn <= 5
    GROUP BY 
        full_address
)
SELECT 
    full_address,
    customer_count,
    customer_names,
    (SELECT COUNT(DISTINCT full_address) FROM AddressSummary) AS total_addresses
FROM 
    AddressSummary
ORDER BY 
    customer_count DESC;
