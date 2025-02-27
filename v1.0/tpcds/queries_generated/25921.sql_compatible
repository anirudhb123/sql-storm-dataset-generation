
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
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
        rank <= 5
),
CustomerAddressInfo AS (
    SELECT 
        tc.full_name,
        tc.cd_gender,
        tc.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip
    FROM 
        TopCustomers AS tc
    JOIN 
        customer_address AS ca ON tc.c_customer_id = SUBSTRING(ca.ca_address_id, 1, 16)
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    ca_city,
    ca_state,
    ca_country,
    ca_zip,
    COUNTRY_MOST_PREFERRED(ca_country) AS most_preferred_country
FROM 
    CustomerAddressInfo
ORDER BY 
    cd_gender, cd_marital_status;
