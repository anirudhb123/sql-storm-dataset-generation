
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
        AND cd.cd_marital_status = 'M'
        AND cd.cd_edcation_status LIKE '%Graduate%'
), AddressCount AS (
    SELECT 
        ca.city,
        COUNT(*) AS address_count
    FROM 
        customer_address AS ca
    GROUP BY 
        ca.city
)
SELECT 
    rc.c_customer_id,
    rc.c_first_name,
    rc.c_last_name,
    rc.ca_city,
    rc.ca_state,
    rc.cd_gender,
    ac.address_count
FROM 
    RankedCustomers AS rc
JOIN 
    AddressCount AS ac ON rc.ca_city = ac.city
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.ca_state, 
    ac.address_count DESC;
