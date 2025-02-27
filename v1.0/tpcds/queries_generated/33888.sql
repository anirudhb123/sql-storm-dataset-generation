
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, 
           ca_city, 
           ca_state, 
           ca_country, 
           0 as level
    FROM customer_address
    WHERE ca_city IS NOT NULL

    UNION ALL

    SELECT ca.ca_address_sk, 
           ca.ca_city,
           ca.ca_state,
           ca.ca_country,
           level + 1
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_city = ah.ca_city AND ca.ca_state = ah.ca_state
    WHERE ah.level < 3
),
ranked_sales AS (
    SELECT ws.web_site_sk, 
           ws.ws_order_number, 
           SUM(ws.ws_net_profit) AS total_profit,
           RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_country IS NOT NULL
    GROUP BY ws.web_site_sk, ws.ws_order_number
),
customer_info AS (
    SELECT c.c_customer_sk, 
           c.c_email_address, 
           d.d_date, 
           cd.cd_gender,
           COALESCE(cd.cd_marital_status, 'N/A') AS marital_status,
           COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
)
SELECT ah.ca_city, 
       ah.ca_state, 
       ah.ca_country,
       ci.c_email_address,
       ci.purchase_estimate,
       rs.total_profit,
       CASE 
           WHEN rs.sales_rank <= 10 THEN 'Top Performer'
           WHEN rs.sales_rank IS NULL THEN 'No Sales'
           ELSE 'Regular Performer'
       END AS performance_category
FROM address_hierarchy ah
LEFT JOIN customer_info ci ON ah.ca_city = ci.ca_city AND ah.ca_state = ci.ca_state
LEFT JOIN ranked_sales rs ON ci.c_customer_sk = rs.web_site_sk
WHERE (ci.gender_purchase_rank <= 5 OR ci.gender_purchase_rank IS NULL)
  AND ah.level = (SELECT MAX(level) FROM address_hierarchy)
ORDER BY ah.ca_city, ah.ca_state;
