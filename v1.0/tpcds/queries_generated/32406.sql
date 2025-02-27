
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 0 AS level
    FROM customer_address
    WHERE ca_city IS NOT NULL

    UNION ALL

    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_country, ah.level + 1
    FROM customer_address a
    INNER JOIN AddressHierarchy ah ON a.ca_state = ah.ca_state
    WHERE ah.level < 5
),
CustomerReturns AS (
    SELECT sr_customer_sk, COUNT(sr_item_sk) AS return_count, SUM(sr_return_amt) AS total_return_amt
    FROM store_returns
    GROUP BY sr_customer_sk
),
CustomerDemographics AS (
    SELECT cd_gender, cd_marital_status, MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status
),
WebSalesSummary AS (
    SELECT 
        ws_ship_mode_sk,
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_sales_price) AS avg_sales_price
    FROM web_sales
    GROUP BY ws_ship_mode_sk, ws_bill_customer_sk
)
SELECT 
    ah.ca_city,
    ah.ca_state,
    ah.ca_country,
    cd.cd_gender,
    cd.cd_marital_status,
    cs.return_count,
    cs.total_return_amt,
    ws.total_profit,
    ws.avg_sales_price
FROM AddressHierarchy ah
LEFT JOIN CustomerReturns cs ON cs.sr_customer_sk IN (
    SELECT c_customer_sk FROM customer WHERE c_current_addr_sk = ah.ca_address_sk
)
JOIN CustomerDemographics cd ON cd.cd_demo_sk IN (
    SELECT c_current_cdemo_sk FROM customer WHERE c_current_addr_sk = ah.ca_address_sk
)
LEFT JOIN WebSalesSummary ws ON ws.ws_bill_customer_sk IN (
    SELECT c_customer_sk FROM customer WHERE c_current_addr_sk = ah.ca_address_sk
)
WHERE (cs.return_count IS NULL OR cs.return_count > 5)
AND (cd.max_purchase_estimate IS NOT NULL OR cd.max_purchase_estimate > 1000)
ORDER BY ah.ca_country, ah.ca_state, ah.ca_city;
