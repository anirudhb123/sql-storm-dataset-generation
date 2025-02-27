
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_city)) AS max_city_length,
        MIN(LENGTH(ca_country)) AS min_country_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT cd_demo_sk) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MIN(cd_dep_count) AS min_dep_count,
        MAX(cd_dep_college_count) AS max_college_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        ws.web_site_id
)

SELECT 
    a.ca_state,
    a.address_count,
    a.avg_street_name_length,
    a.max_city_length,
    a.min_country_length,
    c.cd_gender,
    c.demographic_count,
    c.avg_purchase_estimate,
    c.min_dep_count,
    c.max_college_count,
    s.web_site_id,
    s.total_quantity_sold,
    s.avg_sales_price,
    s.order_count,
    s.total_discount,
    s.total_net_profit
FROM 
    AddressStats a
JOIN 
    CustomerDemographics c ON a.address_count > 100
JOIN 
    SalesData s ON s.total_quantity_sold > 500
ORDER BY 
    a.address_count DESC, c.demographic_count DESC, s.total_net_profit DESC;
