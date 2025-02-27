
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        STRING_AGG(DISTINCT ca_city, ', ') AS unique_cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
GenderDemographics AS (
    SELECT
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_dep_count) AS avg_dependents,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        w.w_warehouse_name,
        SUM(CASE WHEN ws_bill_cdemo_sk IS NOT NULL THEN ws_net_profit ELSE 0 END) AS total_web_sales,
        SUM(CASE WHEN cs_bill_cdemo_sk IS NOT NULL THEN cs_net_profit ELSE 0 END) AS total_catalog_sales,
        SUM(CASE WHEN ss_customer_sk IS NOT NULL THEN ss_net_profit ELSE 0 END) AS total_store_sales
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    LEFT JOIN 
        catalog_sales cs ON w.w_warehouse_sk = cs.cs_warehouse_sk
    LEFT JOIN 
        store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
    GROUP BY 
        w.w_warehouse_name
)
SELECT 
    a.ca_state,
    a.address_count,
    a.max_street_name_length,
    a.avg_street_name_length,
    a.unique_cities,
    g.cd_gender,
    g.customer_count,
    g.avg_dependents,
    g.total_purchase_estimate,
    s.w_warehouse_name,
    s.total_web_sales,
    s.total_catalog_sales,
    s.total_store_sales
FROM 
    AddressStats a
JOIN 
    GenderDemographics g ON a.ca_state = 'CA' -- Example filter
JOIN 
    SalesSummary s ON s.total_web_sales > 10000  -- Example filter
ORDER BY 
    a.ca_state, g.cd_gender, s.total_web_sales DESC;
