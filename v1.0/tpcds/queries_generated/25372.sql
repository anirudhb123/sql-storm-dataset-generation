
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerStats AS (
    SELECT 
        cd_gender, 
        COUNT(DISTINCT c_customer_id) AS customer_count,
        AVG(cd_dep_count) AS avg_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        'Web' AS sales_channel, 
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    UNION ALL
    SELECT 
        'Catalog' AS sales_channel, 
        SUM(cs_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit
    FROM 
        catalog_sales
    UNION ALL
    SELECT 
        'Store' AS sales_channel, 
        SUM(ss_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit
    FROM 
        store_sales
)
SELECT 
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    cs.cd_gender,
    cs.customer_count,
    cs.avg_dependents,
    cs.avg_purchase_estimate,
    ss.sales_channel,
    ss.total_sales,
    ss.total_profit
FROM 
    AddressDetails ad
JOIN 
    CustomerStats cs ON ad.ca_city = cs.city AND ad.ca_state = cs.state
JOIN 
    SalesSummary ss ON cs.customer_count > 0
ORDER BY 
    ad.ca_city, cs.cd_gender, ss.sales_channel;
