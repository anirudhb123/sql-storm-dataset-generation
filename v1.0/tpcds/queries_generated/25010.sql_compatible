
WITH CombinedAddresses AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_street_number, ca_street_name, ca_street_type, ca_city, ca_state, ca_zip
),
CustomerCounts AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.full_address,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, ca.full_address
),
AddressDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_state,
        SUM(cc.customer_count) AS total_customers
    FROM 
        CustomerCounts cc
    JOIN 
        customer_demographics cd ON cc.c_customer_id = cd.cd_demo_sk
    JOIN 
        customer_address ca ON cc.full_address = CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type)
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, ca.ca_state
)
SELECT 
    ad.cd_gender,
    ad.cd_marital_status,
    ad.ca_state,
    ad.total_customers,
    ROW_NUMBER() OVER (PARTITION BY ad.ca_state ORDER BY ad.total_customers DESC) AS rank
FROM 
    AddressDemographics ad
WHERE 
    ad.total_customers > 1
ORDER BY 
    ad.ca_state, ad.total_customers DESC;
