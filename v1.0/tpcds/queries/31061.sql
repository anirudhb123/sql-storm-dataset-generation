
WITH RECURSIVE CustomerTree AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 1 AS depth
    FROM customer
    WHERE c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer)
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ct.depth + 1
    FROM customer c
    JOIN CustomerTree ct ON c.c_current_addr_sk = ct.c_current_addr_sk
    WHERE ct.depth < 5
), SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS item_rank
    FROM web_sales ws
    JOIN CustomerTree ct ON ws.ws_bill_customer_sk = ct.c_customer_sk
    GROUP BY ws.ws_item_sk
), AddressMetrics AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_dep_count) AS average_dependencies
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY ca.ca_address_sk, ca.ca_city
)
SELECT 
    am.ca_city,
    am.customer_count,
    am.average_dependencies,
    sd.ws_item_sk,
    sd.total_quantity,
    sd.total_profit
FROM AddressMetrics am
JOIN SalesData sd ON sd.total_quantity > 100
WHERE am.customer_count > 0 
ORDER BY am.customer_count DESC, sd.total_profit DESC
LIMIT 10;
