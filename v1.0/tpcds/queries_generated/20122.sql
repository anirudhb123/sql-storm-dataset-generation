
WITH RECURSIVE demographics_hierarchy AS (
    SELECT cd_demo_sk, cd_gender, cd_marital_status, cd_education_status, 
           cd_purchase_estimate, cd_credit_rating, cd_dep_count, cd_dep_employed_count, cd_dep_college_count
    FROM customer_demographics
    WHERE cd_demo_sk IS NOT NULL

    UNION ALL

    SELECT d.cd_demo_sk, d.cd_gender, d.cd_marital_status, d.cd_education_status, 
           d.cd_purchase_estimate, d.cd_credit_rating, d.cd_dep_count, d.cd_dep_employed_count, d.cd_dep_college_count
    FROM customer_demographics d
    JOIN demographics_hierarchy h ON d.cd_demo_sk = h.cd_demo_sk + 1
    WHERE d.cd_demo_sk IS NOT NULL
),
sales_data AS (
    SELECT ss.sold_date_sk, ss_store_sk, SUM(ss_ext_sales_price) AS total_sales,
           COUNT(ss_ticket_number) AS total_transactions,
           ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS rank
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE c.c_birth_month = 5
    AND ss.ss_sold_date_sk BETWEEN 10000 AND 20000
    GROUP BY ss.sold_date_sk, ss_store_sk
),
address_data AS (
    SELECT ca_address_sk, ca_city, ca_state, 
           COALESCE(NULLIF(MAX(inv_quantity_on_hand), 0), 100) AS inventory_status
    FROM customer_address ca
    LEFT JOIN inventory i ON ca.ca_address_sk = i.inv_item_sk
    GROUP BY ca_address_sk, ca_city, ca_state
)
SELECT a.ca_city, a.ca_state, 
       COUNT(DISTINCT c.c_customer_id) AS customer_count,
       SUM(dh.cd_purchase_estimate) AS total_estimated_purchase,
       AVG(dh.cd_dep_count) AS avg_dep_count,
       MAX(sd.total_sales) AS peak_sales,
       CASE 
           WHEN COUNT(DISTINCT c.c_customer_id) > 100 THEN 'High Engagement'
           ELSE 'Low Engagement'
       END AS engagement_level,
       COUNT(DISTINCT sd.total_transactions) AS transaction_days
FROM address_data a
JOIN sales_data sd ON a.ca_address_sk = sd.ss_store_sk
JOIN demographics_hierarchy dh ON dh.cd_demo_sk = c.c_current_cdemo_sk
JOIN customer c ON a.ca_address_sk = c.c_current_addr_sk
WHERE a.inventory_status > 50
GROUP BY a.ca_city, a.ca_state
HAVING MAX(sd.total_sales) > 
(SELECT AVG(total_sales) FROM sales_data WHERE total_sales IS NOT NULL)
ORDER BY a.ca_city, a.ca_state;
