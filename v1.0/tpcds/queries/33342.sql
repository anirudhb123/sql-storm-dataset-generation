
WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_year, 
           0 AS level
    FROM customer c
    WHERE c.c_birth_year < 1980
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_year,
           sh.level + 1
    FROM customer c
    JOIN sales_hierarchy sh ON sh.c_customer_sk = c.c_current_cdemo_sk
), customer_info AS (
    SELECT ca.ca_address_id, 
           cd.cd_gender,
           cd.cd_marital_status,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY ca.ca_address_id, cd.cd_gender, cd.cd_marital_status
), demographic_analysis AS (
    SELECT ci.ca_address_id,
           ci.cd_gender,
           ci.cd_marital_status,
           ci.total_orders,
           ci.total_spent,
           CASE 
               WHEN ci.cd_gender = 'M' AND ci.total_spent > 1000 THEN 'High-Spending Male'
               WHEN ci.cd_gender = 'F' AND ci.total_spent > 1000 THEN 'High-Spending Female'
               ELSE 'Other'
           END AS customer_category
    FROM customer_info ci
), rank_analysis AS (
    SELECT da.ca_address_id,
           da.cd_gender,
           da.cd_marital_status,
           da.total_orders,
           da.total_spent,
           da.customer_category,
           RANK() OVER (PARTITION BY da.customer_category ORDER BY da.total_spent DESC) AS rank
    FROM demographic_analysis da
)
SELECT r.ca_address_id,
       r.cd_gender,
       r.cd_marital_status,
       r.total_orders,
       r.total_spent,
       r.customer_category,
       r.rank
FROM rank_analysis r
WHERE r.rank <= 5 
AND r.total_orders > (
    SELECT AVG(total_orders) 
    FROM demographic_analysis
)
ORDER BY r.customer_category, r.total_spent DESC;
