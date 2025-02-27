
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, 
           cd.cd_marital_status, cd.cd_gender, cd.cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS ranking,
           1 AS level
    FROM customer c 
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
    UNION ALL
    SELECT ch.c_customer_sk, ch.c_customer_id, ch.c_first_name, ch.c_last_name, 
           cd.cd_marital_status, cd.cd_gender, cd.cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS ranking,
           ch.level + 1
    FROM CustomerHierarchy ch 
    JOIN customer c ON ch.c_customer_sk = c.c_current_cdemo_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ca.ca_city, 
    ca.ca_state, 
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(ws.ws_net_profit) AS total_net_profit,
    (SELECT COUNT(*) 
     FROM store s 
     WHERE s.s_store_name LIKE 'Super%' OR s.s_store_name IS NULL) AS super_store_count,
    MAX(cd.cd_dep_count) FILTER (WHERE cd.cd_gender = 'F') AS max_dependent_females,
    MAX(cd.cd_dep_count) FILTER (WHERE cd.cd_gender = 'M') AS max_dependent_males
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN (
    SELECT ws_item_sk, COUNT(*) AS refund_count 
    FROM web_returns 
    GROUP BY ws_item_sk
) wr ON ws.ws_item_sk = wr.ws_item_sk
WHERE ca.ca_city NOT LIKE '%town%'
GROUP BY ca.ca_city, ca.ca_state
HAVING COUNT(DISTINCT cd.cd_demo_sk) > 5 
   AND MAX(cd.cd_purchase_estimate) > (
       SELECT AVG(cd_inner.cd_purchase_estimate)
       FROM customer_demographics cd_inner
       WHERE cd_inner.cd_gender = cd.cd_gender
   )
ORDER BY total_net_profit DESC;
