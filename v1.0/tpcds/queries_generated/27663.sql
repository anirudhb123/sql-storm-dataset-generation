
WITH AddressCount AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        STRING_AGG(ca_street_name || ' ' || ca_street_number || ' ' || ca_street_type, ', ') AS full_address
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ac.address_count,
        ac.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressCount ac ON c.c_current_addr_sk = ac.ca_address_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    cd.address_count,
    cd.full_address,
    AVG(ws.ws_net_profit) AS avg_net_profit
FROM 
    CustomerDetails cd 
LEFT JOIN 
    web_sales ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    cd.c_first_name, cd.c_last_name, cd.cd_gender, cd.cd_marital_status, 
    cd.cd_education_status, cd.cd_purchase_estimate, cd.address_count, cd.full_address
ORDER BY 
    avg_net_profit DESC
LIMIT 10;
