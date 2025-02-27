
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk
    FROM customer c
    INNER JOIN CustomerHierarchy ch ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
),
SalesData AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS average_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ws.web_site_sk
),
AddressJoin AS (
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, SUM(ws.ws_net_paid) as total_web_sales
    FROM customer_address ca
    LEFT JOIN web_sales ws ON ca.ca_address_sk = ws.ws_ship_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    coalesce(a.total_web_sales, 0) AS total_web_sales,
    s.total_sales,
    s.order_count,
    s.average_profit
FROM CustomerHierarchy ch
LEFT JOIN AddressJoin a ON ch.c_current_addr_sk = a.ca_address_sk
LEFT JOIN SalesData s ON ch.c_current_cdemo_sk = s.web_site_sk
WHERE (s.total_sales > 1000 OR a.total_web_sales > 500)
      AND (ch.c_first_name IS NOT NULL AND ch.c_last_name IS NOT NULL)
ORDER BY total_web_sales DESC, s.total_sales DESC
LIMIT 100;
