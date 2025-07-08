
WITH sales_hierarchy AS (
    SELECT w.w_warehouse_id, w.w_warehouse_name, COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM warehouse w
    LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_id, w.w_warehouse_name
    HAVING COUNT(DISTINCT ws.ws_order_number) > 0

    UNION ALL

    SELECT w.w_warehouse_id, w.w_warehouse_name, sh.total_orders + COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM warehouse w
    INNER JOIN sales_hierarchy sh ON sh.w_warehouse_id = w.w_warehouse_id
    LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    WHERE sh.total_orders < 100
    GROUP BY w.w_warehouse_id, w.w_warehouse_name, sh.total_orders
), 
sales_summary AS (
    SELECT w.w_warehouse_id, w.w_warehouse_name,
           SUM(ws.ws_net_profit) AS total_profit,
           SUM(ws.ws_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM warehouse w
    LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_id, w.w_warehouse_name
)

SELECT sh.w_warehouse_id, sh.w_warehouse_name,
       CASE 
           WHEN ss.order_count > 50 THEN 'High Volume'
           WHEN ss.order_count BETWEEN 25 AND 50 THEN 'Medium Volume'
           ELSE 'Low Volume' 
       END AS volume_category,
       ss.total_profit,
       ss.total_sales,
       COALESCE(NULLIF(ss.total_sales, 0), 1) AS safe_sales, 
       (ss.total_profit / COALESCE(NULLIF(ss.total_sales, 0), 1)) * 100 AS profit_margin_percentage
FROM sales_hierarchy sh
JOIN sales_summary ss ON sh.w_warehouse_id = ss.w_warehouse_id
ORDER BY profit_margin_percentage DESC
LIMIT 10;
