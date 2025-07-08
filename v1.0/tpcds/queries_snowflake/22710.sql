
WITH RECURSIVE customer_income AS (
    SELECT cd_demo_sk, cd_gender, cd_marital_status, cd_purchase_estimate, 
           (CASE 
                WHEN cd_purchase_estimate IS NULL THEN 'Unknown'
                WHEN cd_purchase_estimate < 50000 THEN 'Low'
                WHEN cd_purchase_estimate BETWEEN 50000 AND 100000 THEN 'Medium'
                ELSE 'High'
            END) AS income_band
    FROM customer_demographics
    WHERE cd_purchase_estimate IS NOT NULL
), ranked_sales AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_net_profit) AS total_profit,
           ROW_NUMBER() OVER(PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), tie_case AS (
    SELECT ws_bill_customer_sk, total_profit,
           DENSE_RANK() OVER(ORDER BY total_profit DESC) AS dense_rank
    FROM ranked_sales
), max_profit AS (
    SELECT ws_bill_customer_sk
    FROM tie_case
    WHERE dense_rank = 1
), addresses_with_counts AS (
    SELECT ca_address_sk, COUNT(c_customer_sk) AS customer_count
    FROM customer
    LEFT JOIN customer_address ON c_current_addr_sk = ca_address_sk
    GROUP BY ca_address_sk
)
SELECT ca.ca_address_id,
       ca.ca_city,
       ca.ca_state,
       ci.income_band,
       COALESCE(ac.customer_count, 0) AS customer_count,
       gp.total_profit
FROM customer_address ca
LEFT JOIN addresses_with_counts ac ON ca.ca_address_sk = ac.ca_address_sk
LEFT JOIN customer_income ci ON ci.cd_demo_sk = (SELECT c.c_current_cdemo_sk 
                                                   FROM customer c 
                                                   WHERE c.c_current_addr_sk = ca.ca_address_sk
                                                   LIMIT 1)
LEFT JOIN (SELECT ws_bill_customer_sk, SUM(ws_net_profit) AS total_profit
           FROM web_sales
           WHERE ws_bill_customer_sk IN (SELECT ws_bill_customer_sk FROM max_profit)
           GROUP BY ws_bill_customer_sk) gp ON gp.ws_bill_customer_sk = (SELECT c.c_customer_sk
                                                                       FROM customer c 
                                                                       WHERE c.c_current_addr_sk = ca.ca_address_sk 
                                                                       LIMIT 1)
WHERE ca.ca_state IS NOT NULL
AND (ci.income_band = 'High' OR ci.income_band IS NULL)
ORDER BY customer_count DESC, total_profit DESC;
