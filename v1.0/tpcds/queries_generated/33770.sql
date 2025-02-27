
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_product_name, i_class_id, 1 AS level
    FROM item
    WHERE i_class_id IS NOT NULL
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_product_name, i.i_class_id, ih.level + 1
    FROM item i
    JOIN item_hierarchy ih ON i.i_class_id = ih.i_class_id
),
sales_summary AS (
    SELECT ws.ws_item_sk, 
           SUM(ws.ws_quantity) AS total_quantity_sold,
           SUM(ws.ws_net_profit) AS total_net_profit,
           AVG(ws.ws_net_paid) AS average_net_paid,
           MAX(ws.ws_net_paid_inc_tax) AS max_paid_inc_tax,
           MIN(ws.ws_net_paid_inc_tax) AS min_paid_inc_tax
    FROM web_sales ws 
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.ws_item_sk
),
customer_info AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           h.hd_income_band_sk,
           CASE 
              WHEN h.hd_buy_potential IS NULL THEN 'Unknown'
              ELSE h.hd_buy_potential
           END AS buying_potential
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics h ON h.hd_demo_sk = c.c_current_hdemo_sk
)
SELECT ci.c_customer_sk,
       ci.c_first_name,
       ci.c_last_name,
       ci.cd_gender,
       SUM(ss.total_quantity_sold) AS total_quantity_purchased,
       MAX(ss.total_net_profit) AS max_net_profit,
       ih.i_product_name AS product_name,
       ih.level AS item_level,
       CASE WHEN SUM(ss.total_quantity_sold) IS NULL 
            THEN 'No Purchases'
            ELSE 'Purchased'
       END AS purchase_status
FROM customer_info ci
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
JOIN item_hierarchy ih ON ss.ws_item_sk = ih.i_item_sk
GROUP BY ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ih.i_product_name, ih.level
HAVING SUM(ss.total_quantity_sold) > 0 OR MAX(ss.total_net_profit) IS NOT NULL
ORDER BY total_quantity_purchased DESC, ci.c_last_name, ci.c_first_name;
