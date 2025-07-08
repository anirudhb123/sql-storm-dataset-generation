
WITH AddressStats AS (
    SELECT 
        ca_state, 
        COUNT(*) AS address_count, 
        LISTAGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), ', ') AS full_address_list
    FROM 
        customer_address
    GROUP BY 
        ca_state
), 
CustomerDemographics AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    a.ca_state, 
    a.address_count, 
    a.full_address_list, 
    c.cd_gender, 
    c.cd_marital_status, 
    c.customer_count
FROM 
    AddressStats a
JOIN 
    CustomerDemographics c ON a.address_count > c.customer_count
ORDER BY 
    a.address_count DESC, c.customer_count DESC;
