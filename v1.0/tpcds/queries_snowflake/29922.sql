
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_zip,
        ca.ca_country,
        Ra.full_name
    FROM 
        customer_address ca
    JOIN 
        RankedCustomers Ra ON ca.ca_address_sk = Ra.c_customer_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(*) AS total_customers,
    LISTAGG(ca.full_name, ', ') AS customer_names,
    SUM(CASE WHEN rc.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
    SUM(CASE WHEN rc.cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_count
FROM 
    CustomerAddresses ca
JOIN 
    RankedCustomers rc ON ca.full_name = rc.full_name
WHERE 
    rc.rank <= 10
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    total_customers DESC, ca.ca_city;
