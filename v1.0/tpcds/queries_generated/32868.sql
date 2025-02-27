
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 1 AS level
    FROM customer_address
    WHERE ca_city IS NOT NULL
    
    UNION ALL

    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_country, h.level + 1
    FROM customer_address a
    JOIN AddressHierarchy h ON a.ca_state = h.ca_state AND a.ca_country = h.ca_country
    WHERE h.level < 3
),
FilteredCustomers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cm.ca_city, cm.ca_state, cm.ca_country,
           RANK() OVER (PARTITION BY cm.ca_country ORDER BY c.c_birth_year DESC) AS BirthRank,
           COUNT(DISTINCT s.s_store_id) AS StoreCount
    FROM customer c
    JOIN customer_address cm ON c.c_current_addr_sk = cm.ca_address_sk
    LEFT JOIN store s ON s.s_store_sk IN (SELECT sr_store_sk FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk)
    WHERE c.c_birth_year IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cm.ca_city, cm.ca_state, cm.ca_country
    HAVING COUNT(DISTINCT s.s_store_id) > 1
),
SalesStatistics AS (
    SELECT ws_bill_customer_sk AS customer_sk,
           SUM(ws_net_paid) AS total_sales,
           COUNT(ws_order_number) AS order_count,
           AVG(ws_net_profit) AS avg_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT fc.c_first_name, fc.c_last_name, fc.ca_city, fc.ca_country, fc.StoreCount,
       ss.total_sales, ss.order_count, ss.avg_profit
FROM FilteredCustomers fc
LEFT OUTER JOIN SalesStatistics ss ON fc.c_customer_sk = ss.customer_sk
WHERE fc.BirthRank = 1
  AND (ss.total_sales IS NULL OR ss.total_sales > 1000)
  AND EXISTS (SELECT 1 FROM AddressHierarchy ah WHERE ah.ca_city = fc.ca_city)
ORDER BY fc.ca_country, fc.StoreCount DESC;
