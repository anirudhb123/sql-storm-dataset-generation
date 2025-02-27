
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        AVG(LENGTH(ca_city)) AS avg_city_name_length,
        AVG(LENGTH(ca_zip)) AS avg_zip_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_marital_status,
        COUNT(DISTINCT c_customer_id) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents,
        COUNT(CASE WHEN cd_gender = 'M' THEN 1 END) AS male_count,
        COUNT(CASE WHEN cd_gender = 'F' THEN 1 END) AS female_count
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_marital_status
),
SalesStats AS (
    SELECT 
        ws.web_site_id AS sales_channel,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_id
)

SELECT 
    a.ca_state,
    a.unique_addresses,
    a.avg_street_name_length,
    a.avg_city_name_length,
    a.avg_zip_length,
    c.cd_marital_status,
    c.total_customers,
    c.avg_dependents,
    c.male_count,
    c.female_count,
    s.sales_channel,
    s.total_quantity_sold,
    s.total_net_profit,
    s.total_orders
FROM 
    AddressStats a
CROSS JOIN 
    CustomerStats c
CROSS JOIN 
    SalesStats s
ORDER BY 
    a.ca_state, c.cd_marital_status, s.total_net_profit DESC;
