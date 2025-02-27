
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate, 
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        full_name, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        cd_purchase_estimate
    FROM 
        RankedCustomers
    WHERE 
        rank <= 10
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_id, 
        ca.ca_street_name, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_zip, 
        tc.full_name
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        TopCustomers tc ON c.c_customer_sk = tc.c_customer_sk
)
SELECT 
    full_name, 
    COUNT(*) AS address_count, 
    STRING_AGG(CONCAT(ca_street_name, ', ', ca_city, ', ', ca_state, ' ', ca_zip) ORDER BY ca_street_name) AS address_list
FROM 
    CustomerAddresses
GROUP BY 
    full_name
ORDER BY 
    address_count DESC;
