
WITH RECURSIVE sales_per_shipment AS (
    SELECT ws_item_sk,
           SUM(ws_quantity) AS total_quantity,
           COUNT(ws_order_number) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rn
    FROM web_sales
    GROUP BY ws_item_sk
),
address_summary AS (
    SELECT ca_state,
           COUNT(DISTINCT c_customer_sk) AS customer_count,
           AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_address
    JOIN customer ON ca_address_sk = c_current_addr_sk
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY ca_state
),
inventory_summary AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand,
           MIN(inv_date_sk) AS first_date_on_hand
    FROM inventory
    GROUP BY inv_item_sk
),
ship_mode_details AS (
    SELECT sm_ship_mode_id, 
           SUM(ws_ext_ship_cost) AS total_shipping_cost
    FROM web_sales
    JOIN ship_mode ON ws_ship_mode_sk = sm_ship_mode_sk
    GROUP BY sm_ship_mode_id
)
SELECT 
    a.ca_state,
    a.customer_count,
    a.avg_purchase_estimate,
    COALESCE(s.total_quantity, 0) AS total_quantity_sold,
    COALESCE(i.total_on_hand, 0) AS total_inventory_on_hand,
    COALESCE(smd.total_shipping_cost, 0) AS total_shipping_cost
FROM address_summary a
LEFT JOIN sales_per_shipment s ON a.ca_state = (SELECT ca_state FROM customer_address WHERE c_current_addr_sk = a.customer_count LIMIT 1)
LEFT JOIN inventory_summary i ON s.ws_item_sk = i.inv_item_sk
LEFT JOIN ship_mode_details smd ON smd.sm_ship_mode_id = 'Standard'
WHERE a.customer_count > 0
  AND (i.total_on_hand IS NULL OR i.total_on_hand > 100)
ORDER BY a.ca_state;
