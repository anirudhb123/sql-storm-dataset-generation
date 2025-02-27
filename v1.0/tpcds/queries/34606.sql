
WITH RECURSIVE CTE_SALES AS (
    SELECT ws_item_sk,
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_quantity) > 100
),
CTE_TOP_ITEMS AS (
    SELECT i_item_id,
           CONCAT(c_first_name, ' ', c_last_name) AS customer_name,
           cs.total_sales,
           ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS item_rank
    FROM item i
    JOIN CTE_SALES cs ON i.i_item_sk = cs.ws_item_sk
    JOIN customer c ON c.c_customer_sk = (
        SELECT ws_bill_customer_sk 
        FROM web_sales 
        WHERE ws_item_sk = i.i_item_sk
        ORDER BY ws_sold_date_sk DESC 
        LIMIT 1
    )
)
SELECT i.i_item_id,
       t.t_hour,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       AVG(ws.ws_net_profit) AS avg_net_profit,
       COUNT(DISTINCT c.c_customer_sk) AS unique_customers
FROM item i
JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
JOIN time_dim t ON t.t_time_sk = ws.ws_sold_time_sk
LEFT JOIN customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE i.i_current_price > 20.0
  AND t.t_hour BETWEEN 9 AND 17
  AND NOT EXISTS (
      SELECT 1
      FROM store_sales ss
      WHERE ss.ss_item_sk = i.i_item_sk
      AND ss.ss_net_paid < 0
  )
GROUP BY i.i_item_id, t.t_hour
HAVING SUM(ws.ws_ext_sales_price) > 1000
   OR (SELECT COUNT(*) FROM CTE_TOP_ITEMS WHERE item_rank < 10) > 0
ORDER BY total_sales DESC
LIMIT 50;
