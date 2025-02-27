
WITH AddressStatistics AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM customer_address
    GROUP BY ca_state
),
DemographicStatistics AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS total_customers,
        AVG(cd_dep_count) AS avg_dependent_count
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender
),
SalesSummary AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_addr_sk
),
CombinedStats AS (
    SELECT 
        a.ca_state,
        a.unique_addresses,
        a.unique_cities,
        a.avg_street_name_length,
        d.cd_gender,
        d.total_customers,
        d.avg_dependent_count,
        s.total_net_profit,
        s.total_orders
    FROM AddressStatistics a
    LEFT JOIN DemographicStatistics d ON a.unique_addresses > 0
    LEFT JOIN SalesSummary s ON s.ws_bill_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_state = a.ca_state)
)
SELECT 
    ca_state,
    cd_gender,
    SUM(total_net_profit) AS aggregated_net_profit,
    COUNT(DISTINCT total_orders) AS order_count,
    MAX(avg_street_name_length) AS max_avg_street_length,
    AVG(avg_dependent_count) AS avg_dependency_per_customer
FROM CombinedStats
GROUP BY ca_state, cd_gender
ORDER BY aggregated_net_profit DESC, order_count DESC;
