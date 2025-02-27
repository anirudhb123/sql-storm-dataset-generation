
WITH CustomerAddresses AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        CustomerAddresses ca ON c.c_current_addr_sk = ca.ca_address_id
),
DemographicGroups AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS customer_count,
        STRING_AGG(full_name, ', ') AS customers
    FROM 
        CustomerDetails
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    CONCAT(cd_gender, ' - ', cd_marital_status) AS demographic_group,
    customer_count,
    customers
FROM 
    DemographicGroups
ORDER BY 
    cd_gender, cd_marital_status;
