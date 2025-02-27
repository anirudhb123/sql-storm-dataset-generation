
WITH AddressAnalysis AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_zip,
        LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_street_name) AS street_name_upper,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        SUBSTRING(ca_city FROM 1 FOR 3) AS city_prefix,
        SUBSTRING(ca_zip FROM 1 FOR 5) AS zip_prefix
    FROM 
        customer_address
),
DemographicsAnalysis AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        md5(cd_credit_rating) AS hashed_credit_rating,
        ARRAY_AGG(DISTINCT cd_education_status) AS education_levels
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
),
SalesAnalysis AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_sales_price) AS avg_sales_price,
        MAX(ws_net_profit) AS max_net_profit,
        STRING_AGG(DISTINCT ws_ship_mode_sk::TEXT, ', ') AS shipping_modes
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    COUNT(DISTINCT d.cd_demo_sk) AS unique_demographics,
    SUM(s.total_quantity) AS total_items_sold,
    AVG(s.avg_sales_price) AS average_price,
    STRING_AGG(DISTINCT a.full_address, '; ') AS aggregated_addresses,
    STRING_AGG(DISTINCT s.shipping_modes, '; ') AS all_shipping_modes
FROM 
    AddressAnalysis a
JOIN 
    DemographicsAnalysis d ON a.ca_zip = d.cd_demo_sk::TEXT
JOIN 
    SalesAnalysis s ON a.ca_address_sk = s.ws_item_sk
GROUP BY 
    a.ca_city, a.ca_state
ORDER BY 
    unique_demographics DESC, total_items_sold DESC;
