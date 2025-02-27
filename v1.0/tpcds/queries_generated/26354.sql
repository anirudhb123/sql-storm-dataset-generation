
WITH AddressParts AS (
    SELECT 
        ca_address_sk, 
        TRIM(ca_street_number) AS street_number,
        UPPER(ca_street_name) AS street_name,
        CONCAT_WS(' ', ca_street_type, ca_suite_number) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
DemographicStats AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS total_count, 
        AVG(cd_dep_count) AS avg_dependents,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        s_store_sk, 
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit
    FROM 
        store_sales
    GROUP BY 
        s_store_sk
)
SELECT 
    a.ca_address_sk,
    a.street_number, 
    a.street_name, 
    a.full_address, 
    a.ca_city,
    a.ca_state,
    d.cd_gender,
    d.total_count,
    d.avg_dependents,
    s.total_sales,
    s.total_profit
FROM 
    AddressParts a
JOIN 
    DemographicStats d ON (a.ca_state = d.cd_gender)  -- This is to showcase joining with an applicable function since there's no direct relation
JOIN 
    SalesSummary s ON a.ca_address_sk = s.s_store_sk
WHERE 
    a.city IS NOT NULL 
    AND d.total_count > 10 
    AND s.total_sales > 1000
ORDER BY 
    a.ca_city, 
    d.total_count DESC;
