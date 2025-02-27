
WITH RECURSIVE sales_hierarchy AS (
    SELECT ws_item_sk,
           SUM(ws_sales_price * ws_quantity) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS total_orders,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_sales_price * ws_quantity) > 1000
),
top_sales AS (
    SELECT ws_item_sk,
           total_sales,
           total_orders
    FROM sales_hierarchy
    WHERE rank <= 10
),
inventory_status AS (
    SELECT inv_date_sk,
           inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_date_sk, inv_item_sk
),
date_reference AS (
    SELECT MAX(d_date_sk) AS max_date_sk
    FROM date_dim
    WHERE d_date = '2002-10-01'
),
inventory_comparison AS (
    SELECT i.inv_item_sk,
           COALESCE(i.total_inventory, 0) AS total_inventory,
           COALESCE(s.total_sales, 0) AS total_sales,
           CASE 
               WHEN COALESCE(i.total_inventory, 0) = 0 THEN NULL
               ELSE COALESCE(s.total_sales, 0) / NULLIF(COALESCE(i.total_inventory, 1), 0)
           END AS sales_to_inventory_ratio
    FROM inventory_status i
    FULL OUTER JOIN top_sales s ON i.inv_item_sk = s.ws_item_sk
)
SELECT w.w_warehouse_id,
       SUM(ic.total_sales) AS total_sales_in_warehouses,
       AVG(ic.sales_to_inventory_ratio) AS avg_sales_to_inventory_ratio,
       COUNT(ic.inv_item_sk) AS items_tracking,
       MAX(ic.total_inventory) AS max_inventory_level_found
FROM inventory_comparison ic
JOIN warehouse w ON w.w_warehouse_sk = (SELECT MAX(inv_warehouse_sk) FROM inventory WHERE inv_item_sk = ic.inv_item_sk)
WHERE ic.sales_to_inventory_ratio IS NOT NULL
GROUP BY w.w_warehouse_id
ORDER BY total_sales_in_warehouses DESC;
