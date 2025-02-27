
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
DemographicInfo AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
),
CombinedInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        AddressInfo a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        DemographicInfo d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    CONCAT(c_first_name, ' ', c_last_name) AS customer_name,
    full_address,
    cd_gender,
    cd_marital_status,
    d.cd_purchase_estimate AS estimated_spending,
    CASE 
        WHEN d.cd_purchase_estimate < 1000 THEN 'Low Value'
        WHEN d.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'High Value'
    END AS value_category
FROM 
    CombinedInfo
WHERE 
    ca_state IN ('CA', 'NY') AND 
    cd_marital_status = 'M'
ORDER BY 
    estimated_spending DESC
LIMIT 10;
