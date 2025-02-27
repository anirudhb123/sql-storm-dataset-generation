
WITH AddressStats AS (
    SELECT 
        ca_state, 
        COUNT(*) AS total_addresses, 
        COUNT(DISTINCT ca_city) AS unique_cities,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM customer_address
    GROUP BY ca_state
), 
DemographicsStats AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS total_demographics, 
        AVG(cd_dep_count) AS avg_dependents,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_gender
),
WebSalesSummary AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_quantity) AS total_quantity_sold
    FROM web_sales
    GROUP BY ws_bill_cdemo_sk
)
SELECT 
    AS.address.ca_state,
    AS.address.total_addresses,
    AS.address.unique_cities,
    AS.address.max_street_name_length,
    AS.address.min_street_name_length,
    AS.address.avg_street_name_length,
    DS.cd_gender,
    DS.total_demographics,
    DS.avg_dependents,
    DS.total_purchase_estimate,
    WS.total_profit,
    WS.total_quantity_sold
FROM AddressStats AS address
JOIN DemographicsStats AS DS ON DS.total_demographics > 100
LEFT JOIN WebSalesSummary AS WS ON WS.ws_bill_cdemo_sk = DS.cd_demo_sk
WHERE address.total_addresses > 50
ORDER BY address.total_addresses DESC, DS.total_purchase_estimate DESC;
