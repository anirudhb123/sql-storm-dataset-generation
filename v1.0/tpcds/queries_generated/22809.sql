
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country
    FROM customer_address
    WHERE ca_city IS NOT NULL
    UNION ALL
    SELECT ca_address_sk, ca_city, ca_state, ca_country
    FROM customer_address
    WHERE ca_state = 'NY' AND ca_country IS NOT NULL
),
sales_data AS (
    SELECT ss_item_sk, SUM(ss_sales_price) AS total_sales, COUNT(ss_ticket_number) AS transaction_count
    FROM store_sales
    GROUP BY ss_item_sk
),
ranked_sales AS (
    SELECT ss_item_sk, total_sales, transaction_count,
           ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY total_sales DESC) AS sales_rank
    FROM sales_data
),
demographics AS (
    SELECT cd_gender, cd_marital_status, AVG(cd_purchase_estimate) AS average_estimate
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status
),
null_check AS (
    SELECT ca.city, ca.state, 
           COALESCE(cd.average_estimate, 0) AS purchase_estimate,
           RANK() OVER (ORDER BY COALESCE(cd.average_estimate, 0) DESC) as rank_estimate
    FROM address_hierarchy ca
    LEFT JOIN demographics cd ON ca_city = cd_gender
)
SELECT ch.city, ch.state, sm.sm_type, sm.sm_carrier,
       CASE 
           WHEN ch.purchase_estimate IS NULL THEN 'N/A'
           ELSE CAST(ch.purchase_estimate AS VARCHAR)
       END AS customer_estimate,
       (SELECT COUNT(*) FROM store_returns sr WHERE sr_store_sk IN (
           SELECT s_store_sk FROM store s WHERE s_city = ch.city
       )) AS return_count
FROM null_check ch
FULL OUTER JOIN ship_mode sm ON ch.rank_estimate = sm.sm_ship_mode_sk
WHERE (ch.city IS NOT NULL OR ch.state IS NOT NULL)
  AND (ch.purchase_estimate > 0 OR sm.sm_type IS NOT NULL)
ORDER BY ch.city, ch.state;
