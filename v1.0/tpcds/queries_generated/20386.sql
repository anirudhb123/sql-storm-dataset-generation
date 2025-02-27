
WITH RecursiveInventory AS (
    SELECT inv_date_sk, inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand,
           ROW_NUMBER() OVER (PARTITION BY inv_item_sk ORDER BY inv_date_sk DESC) AS rn
    FROM inventory
),
RecentSales AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity,
           SUM(ws_net_paid) AS total_net_paid,
           COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
HighDemandItems AS (
    SELECT i_item_sk, i_product_name, COALESCE(ri.inv_quantity_on_hand, 0) AS stock_level,
           rs.total_quantity, rs.total_net_paid, rs.total_orders
    FROM item
    LEFT JOIN RecentSales rs ON item.i_item_sk = rs.ws_item_sk
    LEFT JOIN RecursiveInventory ri ON item.i_item_sk = ri.inv_item_sk AND ri.rn = 1
    WHERE rs.total_quantity IS NOT NULL AND rs.total_quantity > 100
),
SalesAnalysis AS (
    SELECT hdi.i_item_sk, hdi.i_product_name,
           CASE
               WHEN hdi.stock_level < 10 THEN 'LOW'
               WHEN hdi.stock_level BETWEEN 10 AND 50 THEN 'MEDIUM'
               ELSE 'HIGH'
           END AS stock_category,
           hdi.total_quantity, hdi.total_net_paid, hdi.total_orders,
           DENSE_RANK() OVER (PARTITION BY stock_category ORDER BY hdi.total_net_paid DESC) AS sales_rank
    FROM HighDemandItems hdi
)
SELECT s.stock_category, COUNT(*) AS item_count, AVG(s.total_net_paid) AS avg_net_paid,
       SUM(s.total_orders) AS total_orders, 
       MAX(s.total_quantity) AS max_total_quantity
FROM SalesAnalysis s
WHERE s.stock_category IS NOT NULL
  AND (s.total_net_paid > 1000 OR s.total_quantity > 200)
GROUP BY s.stock_category
HAVING COUNT(*) > 5
ORDER BY s.stock_category DESC;
