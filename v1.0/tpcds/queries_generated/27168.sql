
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        full_name,
        gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        RankedCustomers
    WHERE 
        purchase_rank <= 10
),
FormattedAddresses AS (
    SELECT 
        ca_city || ', ' || ca_state || ' ' || ca_zip AS formatted_address,
        ca_country
    FROM 
        customer_address
)
SELECT 
    tc.full_name,
    tc.gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    tc.cd_purchase_estimate,
    fa.formatted_address,
    fa.ca_country
FROM 
    TopCustomers tc
JOIN 
    FormattedAddresses fa ON fa.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = tc.c_customer_sk)
ORDER BY 
    tc.cd_purchase_estimate DESC;
