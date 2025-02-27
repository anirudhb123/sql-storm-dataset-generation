
WITH address_summary AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        STRING_AGG(DISTINCT ca_city, ', ') AS unique_cities,
        STRING_AGG(DISTINCT ca_street_type, ', ') AS street_types
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
demographic_summary AS (
    SELECT 
        cd_gender,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(*) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS orders_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
final_summary AS (
    SELECT 
        a.ca_state,
        a.total_addresses,
        a.unique_cities,
        a.street_types,
        d.cd_gender,
        d.total_dependents,
        d.avg_purchase_estimate,
        s.total_quantity_sold,
        s.total_net_profit,
        s.orders_count
    FROM 
        address_summary a
    LEFT JOIN 
        demographic_summary d ON a.ca_state = 'CA' 
    LEFT JOIN 
        sales_summary s ON d.demographic_count > 0
)
SELECT 
    ca_state,
    total_addresses,
    unique_cities,
    street_types,
    cd_gender,
    total_dependents,
    avg_purchase_estimate,
    total_quantity_sold,
    total_net_profit,
    orders_count
FROM 
    final_summary
ORDER BY 
    total_net_profit DESC, total_quantity_sold DESC
LIMIT 50;
