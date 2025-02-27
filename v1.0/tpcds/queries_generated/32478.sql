
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, 
           i_item_desc, 
           i_brand, 
           i_current_price,
           1 AS level
    FROM item
    WHERE i_item_sk IS NOT NULL
    
    UNION ALL
    
    SELECT ih.i_item_sk, 
           ih.i_item_desc, 
           ih.i_brand, 
           ih.i_current_price * 0.9, 
           ih.level + 1
    FROM item_hierarchy ih
    JOIN item i ON ih.i_item_sk = i.i_item_sk
    WHERE ih.level < 5
),
top_customers AS (
    SELECT c.c_customer_sk, 
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
           cd.cd_gender,
           SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
    HAVING SUM(ws.ws_net_profit) > 10000
),
customer_address_summary AS (
    SELECT ca.ca_address_sk, 
           ca.ca_city, 
           ca.ca_state,
           COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    th.customer_sk,
    th.full_name,
    th.cd_gender,
    CASE 
        WHEN th.cd_gender = 'M' THEN 'Male'
        WHEN th.cd_gender = 'F' THEN 'Female'
        ELSE 'Other' 
    END AS gender_desc,
    ci.ca_city,
    ci.ca_state,
    ci.customer_count,
    i.item_desc,
    i.current_price,
    i.level,
    (CASE 
         WHEN i.current_price IS NULL THEN 'Price not available'
         ELSE 'Price available'
     END) AS price_status
FROM top_customers th
JOIN customer_address_summary ci ON th.c_customer_sk = ci.customer_count
JOIN item_hierarchy i ON i.i_item_sk IN (SELECT DISTINCT ws_item_sk FROM web_sales WHERE ws_net_profit > 100)
WHERE ci.customer_count > 0
ORDER BY th.total_profit DESC, ci.customer_count DESC;
