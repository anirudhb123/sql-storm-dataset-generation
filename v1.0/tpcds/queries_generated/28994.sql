
WITH RankedCustomerAddresses AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(*) AS address_count,
        ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY COUNT(*) DESC) AS rnk
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
CustomerDemographicDetails AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
),
IntersectedData AS (
    SELECT 
        cca.ca_city,
        cca.ca_state,
        cdd.cd_gender,
        cdd.cd_marital_status,
        cdd.cd_education_status,
        cca.address_count,
        cdd.total_purchase_estimate
    FROM 
        RankedCustomerAddresses cca
    JOIN 
        CustomerDemographicDetails cdd ON cca.rnk = 1
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    cc.first_name,
    cc.last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ca.address_count,
    cd.total_purchase_estimate
FROM
    IntersectedData ca
JOIN 
    customer cc ON cc.c_current_addr_sk = (SELECT ca_address_sk FROM customer_address WHERE ca_city = ca.ca_city AND ca_state = ca.ca_state LIMIT 1)
JOIN 
    customer_demographics cd ON cc.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.address_count > 5
ORDER BY 
    total_purchase_estimate DESC, 
    ca_city, 
    ca_state;
