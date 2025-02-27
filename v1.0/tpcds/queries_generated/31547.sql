
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, 
           c.c_first_name || ' ' || c.c_last_name AS full_name, 
           cd.cd_marital_status, 
           cd.cd_gender, 
           cd.cd_purchase_estimate,
           cd.cd_dep_count,
           cd.cd_credit_rating
    FROM customer c 
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_customer_sk IS NOT NULL
    
    UNION ALL
    
    SELECT ch.c_customer_sk, 
           ch.full_name || ' (Child)' AS full_name,
           cd.cd_marital_status, 
           cd.cd_gender, 
           cd.cd_purchase_estimate,
           cd.cd_dep_count,
           cd.cd_credit_rating
    FROM CustomerHierarchy ch
    JOIN customer c ON c.c_customer_sk = ch.c_customer_sk + 1
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)

SELECT ca.ca_state, 
       COUNT(DISTINCT ch.c_customer_sk) AS total_customers,
       AVG(ch.cd_purchase_estimate) AS avg_purchase_estimate,
       SUM(CASE WHEN ch.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
       SUM(CASE WHEN ch.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
       MAX(ch.cd_dep_count) AS max_dependents
FROM CustomerHierarchy ch
JOIN customer_address ca ON ch.c_customer_sk = ca.ca_address_sk
LEFT JOIN date_dim d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d.d_year = EXTRACT(YEAR FROM CURRENT_DATE))
WHERE ca.ca_state IS NOT NULL
GROUP BY ca.ca_state
HAVING AVG(ch.cd_purchase_estimate) > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
ORDER BY total_customers DESC;

WITH CustomerSales AS (
    SELECT ws_bill_customer_sk AS customer_sk,
           SUM(ws_net_paid_inc_tax) AS total_spent,
           RANK() OVER (ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)

SELECT cs.customer_sk,
       cs.total_spent,
       CASE 
           WHEN cs.total_spent IS NULL THEN 'No Purchase'
           WHEN cs.total_spent < 100 THEN 'Low Value Customer'
           WHEN cs.total_spent BETWEEN 100 AND 500 THEN 'Medium Value Customer'
           ELSE 'High Value Customer'
       END AS customer_segment
FROM CustomerSales cs
WHERE cs.sales_rank <= 100
ORDER BY cs.total_spent DESC;
