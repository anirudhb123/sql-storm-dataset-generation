
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 1 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_current_addr_sk = ch.c_customer_sk
), 
sales_summary AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
demographics AS (
    SELECT cd_demo_sk,
           cd_gender,
           cd_marital_status,
           COUNT(c.c_customer_sk) AS customer_count
    FROM customer_demographics cd
    LEFT JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status
),
address_info AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country
    FROM customer_address
    WHERE ca_city IS NOT NULL
)
SELECT ch.c_first_name,
       ch.c_last_name,
       COALESCE(s.total_sales, 0) AS total_sales,
       COALESCE(s.total_orders, 0) AS total_orders,
       d.cd_gender,
       d.cd_marital_status,
       a.ca_city,
       a.ca_state,
       a.ca_country,
       ROW_NUMBER() OVER (PARTITION BY d.cd_gender ORDER BY COALESCE(s.total_sales, 0) DESC) AS gender_rank
FROM customer_hierarchy ch
LEFT JOIN sales_summary s ON ch.c_customer_sk = s.ws_bill_customer_sk
LEFT JOIN demographics d ON ch.c_customer_sk = d.cd_demo_sk
LEFT JOIN address_info a ON ch.c_current_addr_sk = a.ca_address_sk
WHERE (s.total_sales IS NULL OR s.total_sales > 0)
  AND d.customer_count > 1
ORDER BY ch.c_first_name, ch.c_last_name;
