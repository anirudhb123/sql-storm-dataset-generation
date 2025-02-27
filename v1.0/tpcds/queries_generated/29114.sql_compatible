
WITH Address_Stats AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS unique_streets,
        STRING_AGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), ', ') AS full_address_list
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
Max_Addresses AS (
    SELECT 
        ca_city,
        address_count,
        unique_streets,
        full_address_list,
        ROW_NUMBER() OVER (ORDER BY address_count DESC) AS rank
    FROM 
        Address_Stats
)
SELECT 
    ma.ca_city,
    ma.address_count,
    ma.unique_streets,
    ma.full_address_list,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM 
    Max_Addresses ma
JOIN 
    customer c ON c.c_current_addr_sk = ma.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ma.rank <= 5
ORDER BY 
    ma.address_count DESC;
