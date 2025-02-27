
WITH RECURSIVE customer_cycles AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_first_name) AS cycle_count
    FROM customer c
    WHERE c.c_birth_year IS NOT NULL
    UNION ALL
    SELECT cc.c_customer_sk, cc.c_first_name, cc.c_last_name, cc.c_current_cdemo_sk,
           ROW_NUMBER() OVER (PARTITION BY cc.c_customer_sk ORDER BY cc.c_first_name) AS cycle_count
    FROM customer_cycles cc
    JOIN customer c ON cc.c_current_cdemo_sk = c.c_current_cdemo_sk
    WHERE cc.c_customer_sk <> c.c_customer_sk
      AND cc.c_customer_sk IS NOT NULL
      AND cc.c_first_name IS NOT NULL
),
item_shipments AS (
    SELECT i.i_item_sk, i.i_item_desc, SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc
),
inventory_text AS (
    SELECT inv.inv_item_sk,
           CASE 
               WHEN inv.inv_quantity_on_hand IS NULL THEN 'Out of Stock'
               WHEN inv.inv_quantity_on_hand < 10 THEN 'Low Stock'
               ELSE 'In Stock'
           END AS stock_status
    FROM inventory inv
),
customer_details AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status,
           cd.cd_purchase_estimate, cd.cd_credit_rating
    FROM customer_demographics cd
    WHERE cd.cd_demographics_key = (SELECT MAX(cd_demo_sk) FROM customer_demographics)
)
SELECT ca.ca_city, ca.ca_state,
       STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names,
       SUM(i.total_quantity) AS total_items_sold,
       SUM(i.total_profit) AS total_revenue,
       AVG(CASE 
               WHEN i.stock_status = 'Out of Stock' THEN NULL 
               ELSE i.total_quantity 
           END) AS average_sold_when_in_stock
FROM customer c
JOIN customer_cycles cc ON c.c_customer_sk = cc.c_customer_sk
LEFT JOIN customer_details cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN inventory_text i ON i.inv_item_sk = c.c_current_addr_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN item_shipments is ON is.i_item_sk = c.c_current_addr_sk
WHERE (c.c_birth_country IS NOT NULL AND c.c_birth_country <> '')
  AND (cd.cd_purchase_estimate BETWEEN 100 AND 1000 OR cd.cd_credit_rating LIKE 'Good%')
GROUP BY ca.ca_city, ca.ca_state
HAVING COUNT(DISTINCT cc.cycle_count) > 1
ORDER BY total_revenue DESC, ca.ca_state, ca.ca_city;
