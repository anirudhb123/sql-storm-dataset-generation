
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        MAX(LENGTH(ca_street_name)) AS max_street_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesAnalysis AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
),
AddressCustomerJoin AS (
    SELECT 
        ca.ca_state,
        cs.cd_gender,
        cs.total_customers,
        as.max_street_length,
        sa.total_net_profit,
        sa.total_orders
    FROM 
        AddressStats AS ca
    JOIN 
        CustomerStats AS cs ON cs.total_customers > 0
    LEFT JOIN 
        SalesAnalysis AS sa ON sa.ws_bill_cdemo_sk = cs.cd_demo_sk
)
SELECT 
    state,
    gender,
    total_customers,
    max_street_length,
    COALESCE(total_net_profit, 0) AS total_net_profit,
    COALESCE(total_orders, 0) AS total_orders
FROM 
    AddressCustomerJoin
ORDER BY 
    state, gender;
