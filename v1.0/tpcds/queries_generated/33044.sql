
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           1 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
), 
SalesData AS (
    SELECT ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_sales_price,
           DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d) - 30 AND (SELECT MAX(d.d_date_sk) FROM date_dim d)
), 
SalesSummary AS (
    SELECT ch.c_first_name, ch.c_last_name, COUNT(sd.ws_item_sk) AS total_sales,
           SUM(sd.ws_sales_price) AS total_revenue
    FROM CustomerHierarchy ch
    LEFT JOIN SalesData sd ON ch.c_current_cdemo_sk = sd.ws_item_sk
    GROUP BY ch.c_first_name, ch.c_last_name
), 
AddressInfo AS (
    SELECT ca.ca_city, 
           DENSE_RANK() OVER (ORDER BY SUM(ss.ss_net_paid) DESC) AS city_rank
    FROM store_sales ss
    JOIN customer_address ca ON ca.ca_address_sk = ss.ss_addr_sk
    GROUP BY ca.ca_city
)
SELECT ss.first_name, ss.last_name, ss.total_sales, ss.total_revenue, ai.ca_city, ai.city_rank
FROM SalesSummary ss
LEFT JOIN AddressInfo ai ON ss.total_sales > 0 AND ai.city_rank <= 10
WHERE ss.total_revenue IS NOT NULL AND ss.total_sales > 5
ORDER BY ss.total_revenue DESC, ss.total_sales DESC
LIMIT 100;
