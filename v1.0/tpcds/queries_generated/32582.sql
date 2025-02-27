
WITH RECURSIVE sales_hierarchy AS (
    SELECT ws_item_sk, 
           ws_order_number, 
           ws_sales_price, 
           ws_quantity, 
           ws_sold_date_sk, 
           1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2458859 AND 2458890  -- Example date range
    
    UNION ALL
    
    SELECT ws_item_sk, 
           ws_order_number, 
           ws_sales_price * 0.85 AS ws_sales_price,  -- Example discount for demo
           ws_quantity * 2 AS ws_quantity,           -- Example aggregation
           ws_sold_date_sk,
           level + 1
    FROM sales_hierarchy
    WHERE level < 3
),
item_sales AS (
    SELECT i.i_item_id, 
           COALESCE(SUM(sh.ws_quantity), 0) AS total_sales_quantity,
           COALESCE(SUM(sh.ws_sales_price), 0) AS total_sales_price
    FROM item i
    LEFT JOIN sales_hierarchy sh ON i.i_item_sk = sh.ws_item_sk
    GROUP BY i.i_item_id
),
top_items AS (
    SELECT i.i_item_id, 
           is.total_sales_quantity, 
           is.total_sales_price,
           RANK() OVER (ORDER BY is.total_sales_price DESC) AS rank
    FROM item_sales is
    JOIN item i ON i.i_item_id = is.i_item_id
    WHERE is.total_sales_price > 0
)
SELECT ti.i_item_id, 
       ti.total_sales_quantity, 
       ti.total_sales_price,
       CASE 
           WHEN ti.rank <= 10 THEN 'Top 10'
           ELSE 'Others'
       END AS sales_category
FROM top_items ti
ORDER BY ti.rank;
