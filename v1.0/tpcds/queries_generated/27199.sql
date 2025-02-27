
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city, 
        ca_state,
        ROW_NUMBER() OVER(PARTITION BY ca_city, ca_state ORDER BY ca_address_sk) AS address_rank
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND ca_state IS NOT NULL
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS birth_date,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_birth_day = d.d_dom AND c.c_birth_month = d.d_moy AND c.c_birth_year = d.d_year
),
CombinedData AS (
    SELECT 
        ca.full_address,
        ca.ca_city,
        ca.ca_state,
        COUNT(*) AS customer_count,
        STRING_AGG(CONCAT(cd.full_name, ' (', cd.c_customer_id, ')'), ', ') AS customer_names
    FROM 
        RankedAddresses ca
    JOIN 
        CustomerDetails cd ON cd.full_name IS NOT NULL
    GROUP BY 
        ca.full_address, ca.ca_city, ca.ca_state
)
SELECT 
    full_address, 
    ca_city, 
    ca_state, 
    customer_count,
    customer_names
FROM 
    CombinedData
WHERE 
    customer_count > 1
ORDER BY 
    ca_state, ca_city, customer_count DESC;
