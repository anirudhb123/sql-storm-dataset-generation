
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk
    FROM customer
    WHERE c_birth_year IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE c.c_customer_sk <> ch.c_customer_sk
),
item_inventory AS (
    SELECT i.i_item_sk, i.i_item_id, 
           COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_quantity,
           CASE 
               WHEN COALESCE(SUM(inv.inv_quantity_on_hand), 0) = 0 THEN 'Out of Stock'
               WHEN COALESCE(SUM(inv.inv_quantity_on_hand), 0) < 10 THEN 'Low Stock'
               ELSE 'In Stock'
           END AS stock_status
    FROM item i
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
),
sales_summary AS (
    SELECT ws.ws_item_sk, 
           SUM(ws.ws_quantity) AS total_sales, 
           SUM(ws.ws_net_paid) AS total_revenue,
           DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS revenue_rank
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)
SELECT ch.c_first_name, ch.c_last_name, ii.i_item_id, ii.total_quantity, ii.stock_status, ss.total_sales, ss.total_revenue
FROM customer_hierarchy ch
LEFT JOIN item_inventory ii ON ch.c_current_cdemo_sk = ii.i_item_sk
LEFT JOIN sales_summary ss ON ii.i_item_sk = ss.ws_item_sk
WHERE (ss.total_revenue IS NULL OR ss.total_revenue < 100)
  AND (ii.stock_status = 'Low Stock' OR ii.stock_status = 'Out of Stock')
  AND (ch.c_first_name IS NOT NULL OR ch.c_last_name IS NOT NULL)
ORDER BY ch.c_last_name, ch.c_first_name, ii.stock_status DESC;
