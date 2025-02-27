
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
TopSpendingCustomers AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank <= 10
),
AddressStatistics AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT ca.ca_address_sk) AS unique_addresses,
        MAX(ca.ca_zip) AS max_zip_code,
        MIN(ca.ca_zip) AS min_zip_code
    FROM 
        customer_address ca
    GROUP BY 
        ca.ca_state
)
SELECT 
    t.customers_full_name,
    t.cd_gender,
    t.cd_marital_status,
    t.cd_education_status,
    a.ca_state,
    a.unique_addresses,
    a.max_zip_code,
    a.min_zip_code
FROM 
    TopSpendingCustomers t
JOIN 
    AddressStatistics a ON a.ca_state = (SELECT ca.ca_state FROM customer_address ca WHERE ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = t.c_customer_sk))
ORDER BY 
    t.cd_purchase_estimate DESC;
