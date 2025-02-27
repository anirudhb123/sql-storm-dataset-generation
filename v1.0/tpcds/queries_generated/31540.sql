
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_current_cdemo_sk,
           1 AS level
    FROM customer c
    WHERE c.c_customer_sk = 1  -- Starting point for recursion
    UNION ALL
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_current_cdemo_sk,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
), SalesInfo AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_paid) AS total_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 20230101 AND 20230331
    GROUP BY ws.ws_item_sk
), HighValueCustomers AS (
    SELECT cd.cd_demo_sk, 
           SUM(ws.ws_net_paid) AS total_spent
    FROM customer_demographics cd
    JOIN web_sales ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    GROUP BY cd.cd_demo_sk
    HAVING SUM(ws.ws_net_paid) > 1000
), CustomerAddressSummary AS (
    SELECT ca.ca_state,
           COUNT(DISTINCT c.c_customer_sk) AS customer_count,
           AVG(hv.total_spent) AS avg_spent
    FROM customer_address ca
    LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN HighValueCustomers hv ON c.c_current_cdemo_sk = hv.cd_demo_sk
    GROUP BY ca.ca_state
)
SELECT ch.c_first_name,
       ch.c_last_name,
       ca.ca_state,
       ca.customer_count,
       ca.avg_spent
FROM CustomerHierarchy ch
JOIN CustomerAddressSummary ca ON ca.customer_count IS NOT NULL
WHERE EXISTS (
    SELECT 1
    FROM SalesInfo si
    WHERE si.ws_item_sk IN (
        SELECT i.i_item_sk
        FROM item i
        WHERE i.i_current_price > 50.00
    ) AND si.total_sales > 500
) 
ORDER BY ca.avg_spent DESC
LIMIT 10;
