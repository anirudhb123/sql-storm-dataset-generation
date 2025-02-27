
WITH AddressComponents AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS location
    FROM 
        customer_address
),
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_dep_count) AS avg_dependent_count,
        MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        'Web' AS channel,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    UNION ALL
    SELECT 
        'Catalog' AS channel,
        SUM(cs_net_profit) AS total_profit,
        COUNT(cs_order_number) AS total_orders
    FROM 
        catalog_sales
    UNION ALL
    SELECT 
        'Store' AS channel,
        SUM(ss_net_profit) AS total_profit,
        COUNT(ss_ticket_number) AS total_orders
    FROM 
        store_sales
)
SELECT 
    a.ca_address_id,
    a.full_address,
    a.location,
    d.cd_gender,
    d.total_customers,
    d.avg_dependent_count,
    d.max_purchase_estimate,
    s.channel,
    s.total_profit,
    s.total_orders
FROM 
    AddressComponents a
JOIN 
    DemographicStats d ON a.ca_address_id IN (SELECT c_current_addr_sk FROM customer WHERE c_current_addr_sk IS NOT NULL)
CROSS JOIN 
    SalesStats s
ORDER BY 
    a.full_address;
