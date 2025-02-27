
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
),
DemoDetails AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male' 
            ELSE 'Female' 
        END AS gender,
        cd.cd_marital_status AS marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
),
CombinedDetails AS (
    SELECT 
        c.c_customer_id,
        a.full_address,
        a.ca_city,
        a.ca_state,
        d.gender,
        d.marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate
    FROM 
        customer c 
    JOIN 
        AddressDetails a ON c.c_current_addr_sk = a.ca_address_id
    JOIN 
        DemoDetails d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    CONCAT(c.customer_id, '|', c.full_address, '|', c.ca_city, '|', c.ca_state, '|', c.gender, '|', c.marital_status) AS composite_info,
    LENGTH(c.composite_info) AS char_count,
    COUNT(DISTINCT c.cd_education_status) AS unique_education_status_count,
    AVG(d.cd_purchase_estimate) AS average_purchase_estimate
FROM 
    CombinedDetails c
GROUP BY 
    c.customer_id, c.full_address, c.ca_city, c.ca_state, c.gender, c.marital_status
ORDER BY 
    char_count DESC
LIMIT 100;
