
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           CASE 
               WHEN cd.cd_gender = 'M' THEN 'Male' 
               ELSE 'Female' 
           END AS gender_type,
           cd.cd_dependent_count,
           cd.cd_marital_status, 
           ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS marital_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 0
),
address_info AS (
    SELECT ca.ca_address_id, ca.ca_city, ca.ca_state,
           COUNT(DISTINCT c.c_customer_sk) AS num_customers,
           COALESCE(AVG(cd.cd_purchase_estimate), 0) AS avg_purchase_estimate
    FROM customer_address ca
    LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ca.ca_state IN ('CA', 'NY', 'TX')
    GROUP BY ca.ca_address_id, ca.ca_city, ca.ca_state
),
sales_summary AS (
    SELECT ws.ws_sold_date_sk, ws.ws_item_sk,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 1 AND 30 
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
interesting_promo AS (
    SELECT p.p_promo_id, p.p_promo_name, 
           COUNT(DISTINCT cs.cs_order_number) AS promo_effectiveness
    FROM promotion p
    JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    WHERE (p.p_discount_active = 'Y' AND p.p_response_target > 0)
    GROUP BY p.p_promo_id, p.p_promo_name
)
SELECT ch.c_first_name || ' ' || ch.c_last_name AS customer_name,
       ch.gender_type, ch.cd_dependent_count, ch.marital_rank,
       ai.num_customers, ai.avg_purchase_estimate,
       ss.total_quantity, ss.total_sales,
       ip.promo_effectiveness
FROM customer_hierarchy ch
FULL OUTER JOIN address_info ai ON ai.num_customers > 5
FULL OUTER JOIN sales_summary ss ON ss.total_quantity > 100
FULL OUTER JOIN interesting_promo ip ON ip.promo_effectiveness > 10
WHERE (ch.cd_dependent_count IS NULL OR ch.cd_dependent_count > 2)
  AND (ai.avg_purchase_estimate > 100 OR ss.total_sales IS NOT NULL)
ORDER BY ch.c_last_name, ch.c_first_name;
