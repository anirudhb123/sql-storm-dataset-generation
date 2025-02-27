
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 
           1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, 
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
    WHERE ch.level < 5
),
address_data AS (
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, 
           COUNT(DISTINCT ca.ca_address_sk) OVER (PARTITION BY ca.ca_state) AS state_address_count
    FROM customer_address ca
),
demographic_data AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, 
           SUM(cd.cd_purchase_estimate) OVER (PARTITION BY cd.cd_gender) AS total_purchase_by_gender
    FROM customer_demographics cd
    WHERE cd.cd_gender IS NOT NULL
),
sales_summary AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_net_profit) AS total_profit,
           COUNT(ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY ws_bill_customer_sk
),
combined_data AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           ad.ca_city, ad.ca_state, 
           dd.cd_gender, dd.cd_marital_status,
           ss.total_profit, ss.total_orders,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ss.total_profit DESC) AS rn
    FROM customer c
    LEFT JOIN address_data ad ON c.c_current_addr_sk = ad.ca_address_sk
    LEFT JOIN demographic_data dd ON c.c_current_cdemo_sk = dd.cd_demo_sk
    LEFT JOIN sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT DISTINCT *
FROM combined_data
WHERE rn = 1
AND total_profit IS NOT NULL
ORDER BY total_profit DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
