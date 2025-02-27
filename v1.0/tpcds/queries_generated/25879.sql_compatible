
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS rank
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender IN ('M', 'F')
),
FilteredAddresses AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address AS ca
    WHERE 
        ca.ca_city LIKE 'San%' AND ca.ca_state = 'CA'
),
TopCustomers AS (
    SELECT 
        rc.*, 
        fa.full_address
    FROM 
        RankedCustomers AS rc
    LEFT JOIN 
        FilteredAddresses AS fa ON rc.c_customer_id = SUBSTRING(fa.full_address, LENGTH(fa.ca_street_number) + LENGTH(fa.ca_street_name) + LENGTH(fa.ca_street_type) + 3)
    WHERE 
        rc.rank <= 10
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    full_address
FROM 
    TopCustomers
ORDER BY 
    cd_gender, full_name;
