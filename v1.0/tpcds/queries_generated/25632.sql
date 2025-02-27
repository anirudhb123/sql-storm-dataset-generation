
WITH AddressStats AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS total_addresses,
        SUM(CASE WHEN ca_street_type IS NOT NULL THEN 1 ELSE 0 END) AS street_type_count,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS unique_street_names
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
    WHERE 
        cd_gender = 'F' AND 
        cd_marital_status = 'M'
),
SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws_order_number) AS unique_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_id
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.total_addresses,
    a.street_type_count,
    a.unique_street_names,
    c.cd_demo_sk,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    c.cd_purchase_estimate,
    c.cd_credit_rating,
    s.web_site_id,
    s.total_sales,
    s.avg_net_profit,
    s.unique_orders
FROM 
    AddressStats a
JOIN 
    CustomerDemographics c ON a.total_addresses > 100
JOIN 
    SalesData s ON s.total_sales > 1000
WHERE 
    a.ca_state = 'CA'
ORDER BY 
    a.total_addresses DESC, 
    s.total_sales DESC;
