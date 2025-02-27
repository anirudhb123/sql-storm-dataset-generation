
WITH AddressDetails AS (
    SELECT 
        ca_city, 
        ca_state, 
        ca_country,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state, ca_country, ca_street_number, ca_street_name, ca_street_type
),
DemographicInsights AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        MAX(cd_credit_rating) AS highest_credit_rating
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
),
SalesStatistics AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_net_profit) AS average_profit
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.ca_country,
    a.full_address,
    a.address_count,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    d.total_purchase_estimate,
    d.highest_credit_rating,
    s.ws_ship_date_sk,
    s.total_sales,
    s.average_profit
FROM 
    AddressDetails a
JOIN 
    DemographicInsights d ON d.cd_marital_status = 'S'
JOIN 
    SalesStatistics s ON s.ws_ship_date_sk > 0 
ORDER BY 
    a.address_count DESC, 
    d.total_purchase_estimate DESC;
