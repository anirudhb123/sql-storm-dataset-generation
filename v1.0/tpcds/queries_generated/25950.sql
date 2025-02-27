
WITH AddressStats AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(*) AS address_count, 
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length, 
        STRING_AGG(DISTINCT ca_street_type, ', ') AS street_types
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS gender_count, 
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        'Web' AS sales_channel, 
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    UNION ALL
    SELECT 
        'Store' AS sales_channel, 
        SUM(ss_net_profit) AS total_net_profit
    FROM 
        store_sales
    UNION ALL
    SELECT 
        'Catalog' AS sales_channel, 
        SUM(cs_net_profit) AS total_net_profit
    FROM 
        catalog_sales
)
SELECT 
    A.ca_city, 
    A.ca_state, 
    A.address_count, 
    A.avg_street_name_length, 
    A.street_types, 
    C.cd_gender, 
    C.gender_count, 
    C.avg_purchase_estimate, 
    S.sales_channel, 
    S.total_net_profit
FROM 
    AddressStats A 
JOIN 
    CustomerStats C ON A.address_count > (SELECT AVG(address_count) FROM AddressStats)
CROSS JOIN 
    SalesSummary S
ORDER BY 
    A.ca_city, A.ca_state, C.cd_gender;
