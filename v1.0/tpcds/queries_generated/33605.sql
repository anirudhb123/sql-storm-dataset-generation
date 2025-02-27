
WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 0 AS level
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, sh.level + 1
    FROM customer c
    JOIN sales_hierarchy sh ON c.c_current_cdemo_sk = sh.c_customer_sk
),
total_sales AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk > (
        SELECT MAX(d.d_date_sk)
        FROM date_dim d
        WHERE d.d_year = 2023
    )
    GROUP BY ws.ws_item_sk
)
SELECT ca.ca_address_id,
       ca.ca_city,
       ca.ca_state,
       cd.cd_gender,
       SUM(ts.total_sales) AS total_sales_amount,
       COUNT(DISTINCT ts.order_count) AS total_orders,
       COUNT(DISTINCT sh.c_customer_sk) AS preferred_customer_count,
       ROUND(AVG(ts.total_sales), 2) AS avg_sales_per_order
FROM customer_address ca
LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN total_sales ts ON ts.ws_item_sk IN (
    SELECT i.i_item_sk
    FROM item i
    WHERE i.i_current_price IS NOT NULL
    ORDER BY i.i_current_price DESC
    LIMIT 10
)
LEFT JOIN sales_hierarchy sh ON sh.c_customer_sk = c.c_customer_sk
WHERE ca.ca_state IN ('CA', 'NY')
  AND cd.cd_marital_status = 'M'
  AND COALESCE(cd.cd_dep_count, 0) > 1
GROUP BY ca.ca_address_id, ca.ca_city, ca.ca_state, cd.cd_gender
ORDER BY total_sales_amount DESC
LIMIT 50;
