
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd_cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM RankedCustomers
    WHERE rank <= 5
),
AddressDetails AS (
    SELECT 
        ca_address_id,
        ca_street_name,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
    WHERE ca_state IN ('NY', 'CA', 'TX')
),
FullCustomerInfo AS (
    SELECT 
        tc.full_name,
        tc.cd_gender,
        tc.cd_marital_status,
        tc.cd_education_status,
        tc.cd_purchase_estimate,
        ad.ca_street_name,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip
    FROM TopCustomers tc
    JOIN customer c ON c.c_customer_sk = tc.c_customer_sk
    JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    CONCAT(ca_street_name, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
FROM FullCustomerInfo
ORDER BY cd_purchase_estimate DESC;
