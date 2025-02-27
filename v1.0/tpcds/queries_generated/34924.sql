
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT ch.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
)

SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(ws.ws_net_profit) AS total_net_profit,
    MAX(ws.ws_sales_price) AS max_sales_price,
    MIN(ws.ws_sales_price) AS min_sales_price,
    STRING_AGG(DISTINCT cd.cd_gender || ': ' || CD_COUNT, ', ') AS gender_distribution
FROM customer_address ca
LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN (
    SELECT ws_ship_customer_sk, SUM(ws_net_profit) AS ws_net_profit, MAX(ws_sales_price) AS ws_sales_price
    FROM web_sales
    GROUP BY ws_ship_customer_sk
) ws ON c.c_customer_sk = ws.ws_ship_customer_sk
WHERE ca.ca_city IS NOT NULL
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT c.c_customer_sk) > 10 AND AVG(cd.cd_purchase_estimate) IS NOT NULL
ORDER BY total_net_profit DESC
LIMIT 10;
