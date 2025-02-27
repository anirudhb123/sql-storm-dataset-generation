
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           cd.cd_marital_status, cd.cd_gender, 1 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
  
    UNION ALL
  
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           cd.cd_marital_status, cd.cd_gender, ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_addr_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'S'
),
total_sales AS (
    SELECT ws_bill_customer_sk, SUM(ws_net_paid) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
ranked_sales AS (
    SELECT c.c_first_name, c.c_last_name, ts.total_sales,
           RANK() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM total_sales ts
    JOIN customer c ON ts.ws_bill_customer_sk = c.c_customer_sk
),
address_info AS (
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country
    FROM customer_address ca
    WHERE ca.ca_city IS NOT NULL AND ca.ca_state = 'CA'
),
final_output AS (
    SELECT rh.c_first_name, rh.c_last_name, rh.total_sales, ai.ca_city, ai.ca_state, ai.ca_country
    FROM ranked_sales rh
    LEFT JOIN address_info ai ON rh.c_last_name LIKE CONCAT('%', ai.ca_state, '%')
)
SELECT * FROM final_output
WHERE total_sales > 1000
ORDER BY sales_rank;
