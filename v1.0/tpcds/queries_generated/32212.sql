
WITH RECURSIVE popular_items AS (
    SELECT i_item_sk, i_product_name, i_current_price, 1 AS popularity
    FROM item
    WHERE i_current_price IS NOT NULL
    UNION ALL
    SELECT i.item_sk, i.i_product_name, i.i_current_price, pi.popularity + 1
    FROM item i
    JOIN popular_items pi ON i.i_item_sk = pi.i_item_sk
    WHERE pi.popularity < 5
),
sales_data AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity, SUM(ws.ws_net_profit) AS total_profit, 
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
store_sales_data AS (
    SELECT ss.ss_item_sk, SUM(ss.ss_quantity) AS total_quantity, SUM(ss.ss_net_profit) AS total_profit,
           COUNT(DISTINCT ss.ss_ticket_number) AS order_count
    FROM store_sales ss
    GROUP BY ss.ss_item_sk
),
combined_sales AS (
    SELECT COALESCE(w.ws_item_sk, s.ss_item_sk) AS item_sk,
           COALESCE(w.total_quantity, 0) + COALESCE(s.total_quantity, 0) AS combined_quantity,
           COALESCE(w.total_profit, 0) + COALESCE(s.total_profit, 0) AS combined_profit,
           COALESCE(w.order_count, 0) + COALESCE(s.order_count, 0) AS combined_order_count
    FROM sales_data w
    FULL OUTER JOIN store_sales_data s ON w.ws_item_sk = s.ss_item_sk
),
final_report AS (
    SELECT i.i_product_name, cs.combined_quantity, cs.combined_profit, 
           ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY cs.combined_profit DESC) AS profit_rank
    FROM combined_sales cs
    JOIN item i ON cs.item_sk = i.i_item_sk
)
SELECT f.i_product_name, f.combined_quantity, f.combined_profit, f.profit_rank
FROM final_report f
WHERE f.profit_rank <= 10
ORDER BY f.combined_profit DESC;
