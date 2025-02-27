
WITH AddressCounts AS (
    SELECT ca_state,
           COUNT(*) AS total_addresses,
           COUNT(DISTINCT ca_city) AS unique_cities
    FROM customer_address
    GROUP BY ca_state
),
NameAndReturnCount AS (
    SELECT c.c_first_name || ' ' || c.c_last_name AS full_name,
           COUNT(sr.sr_ticket_number) AS total_returns
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY full_name
),
SalesStatistics AS (
    SELECT ws_bill_cdemo_sk,
           SUM(ws_net_profit) AS total_net_profit,
           COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_cdemo_sk
)
SELECT a.ca_state,
       a.total_addresses,
       a.unique_cities,
       n.full_name,
       n.total_returns,
       s.total_net_profit,
       s.total_orders
FROM AddressCounts a
JOIN NameAndReturnCount n ON a.total_addresses > 50
JOIN SalesStatistics s ON n.full_name LIKE '%John%' AND n.full_name NOT LIKE '%Doe%'
WHERE a.unique_cities > 3
ORDER BY a.total_addresses DESC, s.total_net_profit DESC;
