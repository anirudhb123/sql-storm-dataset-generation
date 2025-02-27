
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
AddressAnalysis AS (
    SELECT 
        ca_state, 
        COUNT(*) AS total_addresses,
        STRING_AGG(DISTINCT ca_zip) AS zip_codes,
        STRING_AGG(DISTINCT ca_city) AS cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_net_paid) AS total_spent,
        AVG(ws_net_paid) AS avg_spent
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    aa.total_addresses,
    aa.zip_codes,
    aa.cities,
    si.total_spent,
    si.avg_spent
FROM 
    CustomerInfo ci
LEFT JOIN 
    AddressAnalysis aa ON ci.ca_state = aa.ca_state
LEFT JOIN 
    SalesInfo si ON ci.c_customer_id = si.customer_id
WHERE 
    ci.cd_gender = 'F' AND 
    si.total_spent > 500
ORDER BY 
    si.avg_spent DESC
LIMIT 100;
