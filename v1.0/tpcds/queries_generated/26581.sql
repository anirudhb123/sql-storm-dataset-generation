
WITH AddressWords AS (
    SELECT 
        ca_address_sk,
        ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type || 
        CASE WHEN ca_suite_number IS NOT NULL THEN ' Suite ' || ca_suite_number ELSE '' END AS full_address
    FROM 
        customer_address
),
DemographicCounts AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, 
        cd_marital_status
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    A.ca_address_sk,
    A.full_address,
    D.cd_gender,
    D.cd_marital_status,
    D.demographic_count,
    S.total_net_profit,
    S.total_orders
FROM 
    AddressWords A
JOIN 
    customer C ON A.ca_address_sk = C.c_current_addr_sk
LEFT JOIN 
    DemographicCounts D ON C.c_current_cdemo_sk = D.cd_demo_sk
LEFT JOIN 
    SalesData S ON C.c_customer_sk = S.ws_bill_customer_sk
WHERE 
    A.full_address LIKE '%Street%' AND
    D.demographic_count > 1 AND
    S.total_net_profit > 1000
ORDER BY 
    A.ca_address_sk, 
    D.cd_gender;
