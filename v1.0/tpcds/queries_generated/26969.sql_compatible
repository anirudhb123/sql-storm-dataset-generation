
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
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
BestCustomers AS (
    SELECT
        r.full_name,
        r.cd_gender,
        r.cd_marital_status,
        r.cd_education_status,
        r.cd_purchase_estimate
    FROM 
        RankedCustomers r
    WHERE 
        r.rank <= 5
),
CustomerAddresses AS (
    SELECT 
        a.ca_address_id,
        a.ca_city,
        a.ca_state,
        c.full_name
    FROM 
        customer_address a
    JOIN 
        customer c ON c.c_current_addr_sk = a.ca_address_sk
),
FinalOutput AS (
    SELECT 
        b.full_name,
        b.cd_gender,
        b.cd_marital_status,
        b.cd_education_status,
        b.cd_purchase_estimate,
        a.ca_address_id,
        a.ca_city,
        a.ca_state,
        COUNT(*) OVER (PARTITION BY b.cd_gender) AS total_customers
    FROM 
        BestCustomers b
    LEFT JOIN 
        CustomerAddresses a ON b.full_name = a.full_name
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    ca_address_id,
    ca_city,
    ca_state,
    total_customers
FROM 
    FinalOutput
ORDER BY 
    cd_purchase_estimate DESC, 
    full_name;
