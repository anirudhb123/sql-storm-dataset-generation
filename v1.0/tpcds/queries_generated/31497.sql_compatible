
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_demo_sk, cd.cd_gender, 
           hd.hd_income_band_sk, hd.hd_dep_count, 1 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_demo_sk, cd.cd_gender, 
           hd.hd_income_band_sk, hd.hd_dep_count, ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_hdemo_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE hd.hd_dep_count IS NOT NULL
), CustomerSales AS (
    SELECT c.c_customer_sk, SUM(ss.ss_net_paid) AS total_spent
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
), SalesSummary AS (
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.cd_gender, 
           cs.total_spent, 
           CASE
               WHEN cs.total_spent IS NULL THEN 'No Sales'
               WHEN cs.total_spent < 100 THEN 'Low Value'
               WHEN cs.total_spent >= 100 AND cs.total_spent <= 1000 THEN 'Medium Value'
               ELSE 'High Value'
           END AS customer_value
    FROM CustomerHierarchy ch
    LEFT JOIN CustomerSales cs ON ch.c_customer_sk = cs.c_customer_sk
)
SELECT ws.web_site_id, ws.web_name, SUM(ss.ss_net_profit) AS total_net_profit,
       AVG(COALESCE(cs.total_spent, 0)) AS avg_spent_per_customer,
       COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
       STRING_AGG(DISTINCT CONCAT(ss.ss_item_sk, ': ', ss.ss_sales_price)::text, ', ') AS item_sales
FROM web_site ws
JOIN web_sales wsales ON ws.web_site_sk = wsales.ws_web_site_sk
JOIN store_sales ss ON ss.ss_ticket_number = wsales.ws_order_number
LEFT JOIN SalesSummary cs ON ss.ss_customer_sk = cs.c_customer_sk
WHERE cs.customer_value = 'High Value'
GROUP BY ws.web_site_id, ws.web_name
ORDER BY total_net_profit DESC
LIMIT 10;
