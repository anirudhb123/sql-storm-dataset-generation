
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(CASE WHEN ca_city IS NOT NULL THEN 1 ELSE 0 END) AS city_present_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicsStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents,
        MAX(cd_purchase_estimate) AS max_estimate,
        MIN(cd_purchase_estimate) AS min_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        ws_bill_addr_sk,
        COUNT(ws_order_number) AS total_sales,
        SUM(ws_sales_price) AS total_revenue,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_addr_sk
)
SELECT 
    A.ca_state,
    A.unique_addresses,
    A.total_addresses,
    A.avg_street_name_length,
    A.city_present_count,
    D.cd_gender,
    D.total_customers,
    D.avg_dependents,
    D.max_estimate,
    D.min_estimate,
    S.total_sales,
    S.total_revenue,
    S.avg_sales_price
FROM 
    AddressStats A
JOIN 
    DemographicsStats D ON D.total_customers > 100
LEFT JOIN 
    SalesStats S ON S.ws_bill_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_state = A.ca_state)
WHERE 
    A.total_addresses > 10
ORDER BY 
    A.ca_state, D.cd_gender;
