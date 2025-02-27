
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        STRING_AGG(ca_street_name, ', ') AS concatenated_street_names,
        STRING_AGG(ca_city, ', ') AS concatenated_cities,
        COUNT(DISTINCT ca_zip) AS distinct_zip_codes
    FROM 
        customer_address
    GROUP BY 
        ca_state
), DemographicSummary AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_dep_count) AS average_dependents,
        STRING_AGG(cd_marital_status, ', ') AS marital_statuses,
        STRING_AGG(cd_education_status, ', ') AS education_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
), SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit,
        STRING_AGG(ws_shipping_date_sk::TEXT, ', ') AS shipped_dates
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.concatenated_street_names,
    a.distinct_zip_codes,
    d.cd_gender,
    d.total_customers,
    d.average_dependents,
    d.marital_statuses,
    d.education_statuses,
    s.total_orders,
    s.total_net_profit,
    s.shipped_dates
FROM 
    AddressSummary a
JOIN 
    DemographicSummary d ON a.total_addresses > 100
JOIN 
    SalesSummary s ON d.total_customers > 50
ORDER BY 
    a.ca_state, d.cd_gender;
