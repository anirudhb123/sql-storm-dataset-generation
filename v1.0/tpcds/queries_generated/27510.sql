
WITH AddressAnalysis AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        SUM(LENGTH(ca_street_name) + LENGTH(ca_city) + LENGTH(ca_zip)) AS total_characters,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicAnalysis AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents,
        MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        MAX(ws_net_profit) AS max_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
),
FinalBenchmark AS (
    SELECT 
        aa.ca_state,
        da.cd_gender,
        ss.total_sales,
        ss.order_count,
        ss.max_profit,
        aa.unique_addresses,
        aa.total_characters,
        aa.avg_street_name_length,
        da.total_customers,
        da.avg_dependents,
        da.max_purchase_estimate
    FROM 
        AddressAnalysis aa
    JOIN 
        DemographicAnalysis da ON 1=1
    JOIN 
        SalesSummary ss ON ss.ws_bill_cdemo_sk = da.cd_demo_sk
)
SELECT *
FROM FinalBenchmark
WHERE total_sales > 1000
ORDER BY total_sales DESC, unique_addresses DESC;
