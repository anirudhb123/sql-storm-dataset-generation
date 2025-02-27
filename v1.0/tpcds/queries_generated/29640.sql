
WITH AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        SUM(CASE WHEN ca_city LIKE '%Park%' THEN 1 ELSE 0 END) AS park_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM customer_address
    GROUP BY ca_state
),
CustomerDetails AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_id) AS total_customers,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM customer_demographics
    JOIN customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status
),
DateSummary AS (
    SELECT 
        d_year,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY d_year
)
SELECT 
    ac.ca_state,
    ac.unique_addresses, 
    ac.park_addresses,
    ac.avg_street_name_length,
    cd.total_customers,
    cd.total_purchase_estimate,
    ds.total_orders,
    ds.total_net_profit
FROM AddressCounts ac
JOIN CustomerDetails cd ON ac.ca_state = (
    SELECT ca_state FROM customer_address WHERE ca_address_sk = (
        SELECT c_current_addr_sk FROM customer WHERE c_current_cdemo_sk = cd.cd_demo_sk
    )
    LIMIT 1
)
JOIN DateSummary ds ON ds.d_year = YEAR(CURDATE())
ORDER BY ac.ca_state;
