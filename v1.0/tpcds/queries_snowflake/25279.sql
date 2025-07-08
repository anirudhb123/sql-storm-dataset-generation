
WITH ProcessedAddresses AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        UPPER(ca_country) AS country_upper
    FROM 
        customer_address
), 
DemographicStatistics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS count_by_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependent_count,
        MIN(cd_dep_count) AS min_dependent_count,
        LISTAGG(cd_education_status, ', ') WITHIN GROUP (ORDER BY cd_education_status) AS unique_education_statuses,
        cd_demo_sk
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_demo_sk
), 
SalesSummary AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_ext_sales_price) AS total_sales_value,
        MAX(ws_net_profit) AS highest_net_profit
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    d.count_by_gender,
    d.avg_purchase_estimate,
    d.max_dependent_count,
    d.min_dependent_count,
    s.total_quantity_sold,
    s.total_sales_value,
    s.highest_net_profit,
    d.unique_education_statuses
FROM 
    ProcessedAddresses a
LEFT JOIN 
    SalesSummary s ON a.ca_address_sk = s.ws_bill_cdemo_sk
LEFT JOIN 
    DemographicStatistics d ON s.ws_bill_cdemo_sk = d.cd_demo_sk
WHERE 
    a.ca_state = 'CA' AND 
    a.ca_zip LIKE '9%' 
ORDER BY 
    a.ca_city ASC, 
    s.total_sales_value DESC
LIMIT 100;
