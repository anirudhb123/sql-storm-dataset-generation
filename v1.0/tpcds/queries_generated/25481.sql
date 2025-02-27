
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ca.ca_city, 
        ca.ca_state, 
        ROW_NUMBER() OVER(PARTITION BY ca.ca_state ORDER BY c.c_birth_year DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_marital_status = 'M' AND 
        cd.cd_gender = 'F'
),
AddressSummary AS (
    SELECT 
        ca.ca_state,
        COUNT(*) AS customer_count,
        STRING_AGG(DISTINCT ca.ca_city, ', ') AS cities
    FROM 
        customer_address ca
    GROUP BY 
        ca.ca_state
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    rc.ca_city,
    rc.ca_state,
    asum.customer_count,
    asum.cities
FROM 
    RankedCustomers rc
JOIN 
    AddressSummary asum ON rc.ca_state = asum.ca_state
WHERE 
    rc.rank <= 5
ORDER BY 
    rc.ca_state, rc.full_name;
