
WITH RECURSIVE Inventory_CTE AS (
    SELECT inv_date_sk, inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand,
           ROW_NUMBER() OVER (PARTITION BY inv_item_sk ORDER BY inv_date_sk DESC) as rn
    FROM inventory
),
Sales_Summary AS (
    SELECT ws_item_sk,
           SUM(ws_quantity) AS total_quantity_sold,
           AVG(ws_net_profit) AS average_profit,
           COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_item_sk
),
Customer_Segment AS (
    SELECT cd_demo_sk, cd_gender, cd_marital_status,
           CASE 
               WHEN cd_purchase_estimate < 100 THEN 'Low'
               WHEN cd_purchase_estimate BETWEEN 100 AND 500 THEN 'Medium'
               ELSE 'High'
           END AS customer_value_segment
    FROM customer_demographics
)
SELECT 
    ia.inv_item_sk,
    COALESCE(ss.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(ss.average_profit, 0) AS average_profit,
    seg.customer_value_segment,
    ROW_NUMBER() OVER (PARTITION BY seg.customer_value_segment ORDER BY ia.inv_quantity_on_hand DESC) as rank_within_segment,
    IA.inv_quantity_on_hand
FROM Inventory_CTE ia
LEFT JOIN Sales_Summary ss ON ia.inv_item_sk = ss.ws_item_sk
LEFT JOIN customer c ON c.c_current_hdemo_sk = (SELECT hd_demo_sk FROM household_demographics WHERE hd_demo_sk = c.c_current_hdemo_sk)
LEFT JOIN Customer_Segment seg ON c.c_current_hdemo_sk = seg.cd_demo_sk
WHERE ia.rn = 1
  AND ia.inv_quantity_on_hand IS NOT NULL
ORDER BY seg.customer_value_segment, total_quantity_sold DESC;
