
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, 
           c_first_name, 
           c_last_name, 
           c_current_cdemo_sk,
           0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_current_cdemo_sk,
           ch.level + 1
    FROM customer c
    INNER JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
    WHERE ch.level < 5
),
sales_summary AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_net_profit) AS total_net_profit,
           COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY ws_bill_customer_sk
),
address_info AS (
    SELECT ca_address_sk, 
           CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM customer_address
),
gender_distribution AS (
    SELECT cd_gender,
           COUNT(*) AS count
    FROM customer_demographics
    GROUP BY cd_gender
),
top_customers AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           ss.total_net_profit,
           ss.total_orders,
           ad.full_address
    FROM customer c
    LEFT JOIN sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN address_info ad ON c.c_current_addr_sk = ad.ca_address_sk
    WHERE ss.total_net_profit > (SELECT AVG(total_net_profit) FROM sales_summary)
    ORDER BY ss.total_net_profit DESC
    LIMIT 10
)
SELECT th.c_customer_sk,
       th.c_first_name,
       th.c_last_name,
       th.total_net_profit,
       th.total_orders,
       th.full_address,
       gd.count AS gender_count
FROM top_customers th
LEFT JOIN gender_distribution gd ON gd.cd_gender = (SELECT cd_gender FROM customer_demographics WHERE cd_demo_sk = th.c_current_cdemo_sk LIMIT 1)
WHERE th.total_orders > 5
ORDER BY th.total_net_profit DESC;
