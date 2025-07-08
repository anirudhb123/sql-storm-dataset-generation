
WITH address_stats AS (
    SELECT 
        ca_state, 
        COUNT(*) AS address_count, 
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        LISTAGG(DISTINCT ca_city, ', ') WITHIN GROUP (ORDER BY ca_city) AS unique_cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
demographics_stats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        LISTAGG(DISTINCT cd_marital_status, ', ') WITHIN GROUP (ORDER BY cd_marital_status) AS marital_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
sales_stats AS (
    SELECT 
        ws_bill_addr_sk, 
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(*) AS total_orders,
        LISTAGG(DISTINCT CAST(ws_ship_mode_sk AS TEXT), ', ') WITHIN GROUP (ORDER BY ws_ship_mode_sk) AS shipping_modes
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
)
SELECT 
    a.ca_state, 
    a.address_count, 
    a.avg_street_name_length, 
    a.unique_cities,
    d.cd_gender, 
    d.demographic_count, 
    d.avg_purchase_estimate, 
    d.marital_statuses,
    s.total_net_profit, 
    s.total_orders, 
    s.shipping_modes
FROM 
    address_stats a
JOIN 
    demographics_stats d ON a.address_count > 100
JOIN 
    sales_stats s ON a.address_count = s.ws_bill_addr_sk
ORDER BY 
    a.ca_state, d.cd_gender;
