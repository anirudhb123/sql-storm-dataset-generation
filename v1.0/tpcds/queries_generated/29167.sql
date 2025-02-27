
WITH AddressStats AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS unique_street_names,
        STRING_AGG(DISTINCT ca_street_type, ', ') AS street_types
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS education_levels
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        s_store_name,
        COUNT(ws_order_number) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_sales_price) AS average_price
    FROM 
        web_sales 
    JOIN 
        store ON ws_store_sk = s_store_sk
    GROUP BY 
        s_store_name
)
SELECT 
    a.ca_city, 
    a.ca_state, 
    a.address_count,
    a.unique_street_names,
    c.cd_gender,
    c.demographic_count,
    c.education_levels,
    s.s_store_name,
    s.total_sales,
    s.total_profit,
    s.average_price
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON a.ca_state = 'CA' -- Focusing on California demographic
JOIN 
    SalesStats s ON s.total_sales > 100 -- Stores with substantial sales
ORDER BY 
    a.address_count DESC, c.demographic_count DESC, s.total_sales DESC;
