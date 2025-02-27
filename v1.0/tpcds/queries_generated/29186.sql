
WITH AddressCounts AS (
    SELECT 
        ca_state, 
        COUNT(*) AS address_count 
    FROM 
        customer_address 
    GROUP BY 
        ca_state
),
TopDemographics AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        COUNT(*) AS demographic_count 
    FROM 
        customer_demographics 
    GROUP BY 
        cd_gender, 
        cd_marital_status 
    ORDER BY 
        demographic_count DESC 
    LIMIT 5
),
SalesSummary AS (
    SELECT 
        ws_bill_cdemo_sk, 
        SUM(ws_net_paid) AS total_spent 
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    ca.ca_city AS city, 
    ac.address_count, 
    td.cd_gender, 
    td.cd_marital_status, 
    ss.total_spent 
FROM 
    customer_address ca 
JOIN 
    AddressCounts ac ON ca.ca_state = ac.ca_state 
JOIN 
    TopDemographics td ON td.cd_demo_sk = ca.ca_address_sk 
LEFT JOIN 
    SalesSummary ss ON ss.ws_bill_cdemo_sk = ca.ca_address_sk 
WHERE 
    ac.address_count > 10 
ORDER BY 
    total_spent DESC, 
    city ASC;
