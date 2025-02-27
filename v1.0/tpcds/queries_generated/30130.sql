
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, i_brand, 1 AS level
    FROM item
    WHERE i_current_price IS NOT NULL
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_current_price, i.i_brand, ih.level + 1
    FROM item i
    JOIN item_hierarchy ih ON i.i_item_sk = ih.i_item_sk + 1
    WHERE ih.level < 10
), sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws_sold_date_sk
),
customer_ranking AS (
    SELECT 
        c_customer_sk,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS rn,
        cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd_purchase_estimate IS NOT NULL
),
inventory_summary AS (
    SELECT 
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT 
    ca.ca_city,
    SUM(ss.total_net_profit) AS total_net_profit,
    AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(COALESCE(i.current_price, 0)) AS total_item_value
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
INNER JOIN sales_summary ss ON ss.ws_sold_date_sk = date_part('year', CURRENT_DATE)
LEFT JOIN (SELECT i_item_sk, SUM(i_current_price) AS current_price FROM item_hierarchy GROUP BY i_item_sk) i ON 1=1
LEFT JOIN inventory_summary inv ON inv.inv_warehouse_sk = 1
WHERE ca.ca_state = 'CA'
AND cd.cd_marital_status = 'M'
AND cd.cd_dep_count > 0
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT c.c_customer_sk) > 5
ORDER BY total_net_profit DESC
LIMIT 10;
