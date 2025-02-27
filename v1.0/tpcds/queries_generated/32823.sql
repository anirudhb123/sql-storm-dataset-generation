
WITH RECURSIVE sales_data AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_sales_price, 
           ws_net_profit, 1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk > (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    UNION ALL
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_sales_price * 1.1 AS ws_sales_price,
           ws_net_profit + 100, level + 1
    FROM sales_data
    WHERE level < 5
), aggregated_sales AS (
    SELECT ws_item_sk,
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_sales_price) AS total_sales,
           SUM(ws_net_profit) AS total_profit,
           COUNT(DISTINCT ws_sold_date_sk) AS sales_days
    FROM sales_data
    GROUP BY ws_item_sk
), high_profit_items AS (
    SELECT i_item_id, i_item_desc, a.total_quantity, a.total_sales, a.total_profit, a.sales_days
    FROM item i
    JOIN aggregated_sales a ON i.i_item_sk = a.ws_item_sk
    WHERE a.total_profit > (SELECT AVG(total_profit) FROM aggregated_sales)
)
SELECT h.i_item_id,
       h.i_item_desc,
       h.total_quantity,
       h.total_sales,
       h.total_profit,
       h.sales_days,
       COALESCE(w.w_warehouse_name, 'No Warehouse') AS warehouse_name,
       CASE WHEN h.total_sales IS NULL THEN 'No Sales'
            WHEN h.total_sales > 1000 THEN 'High Sales'
            ELSE 'Low Sales' END AS sales_category
FROM high_profit_items h
LEFT JOIN warehouse w ON h.total_quantity > w.w_warehouse_sq_ft
ORDER BY h.total_profit DESC, h.total_quantity ASC
LIMIT 50;
