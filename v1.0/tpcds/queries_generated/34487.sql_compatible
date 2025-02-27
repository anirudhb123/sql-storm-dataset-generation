
WITH RECURSIVE sales_hierarchy AS (
    SELECT s.store_sk AS store_sk, s.store_name, ss.ss_sold_date_sk, ss.ss_item_sk, SUM(ss.ss_quantity) AS total_quantity
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE ss.ss_sold_date_sk BETWEEN 20220101 AND 20220131
    GROUP BY s.store_sk, s.store_name, ss.ss_sold_date_sk, ss.ss_item_sk
    UNION ALL
    SELECT h.store_sk, h.store_name, h.ss_sold_date_sk, h.ss_item_sk, h.total_quantity
    FROM sales_hierarchy h
    JOIN store s ON h.store_sk = s.s_store_sk
    WHERE h.total_quantity > 100
), item_summary AS (
    SELECT i.i_item_sk, i.i_item_desc, SUM(ws.ws_quantity) AS total_sold
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 20220101 AND 20220131
    GROUP BY i.i_item_sk, i.i_item_desc
), top_items AS (
    SELECT item_summary.i_item_sk, item_summary.i_item_desc, item_summary.total_sold,
           DENSE_RANK() OVER (ORDER BY item_summary.total_sold DESC) AS item_rank
    FROM item_summary
    WHERE item_summary.total_sold > 50
)
SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
       ca.ca_city, ca.ca_state, 
       COALESCE(SUM(ss.ss_sales_price), 0) AS total_sales, 
       ARRAY_AGG(DISTINCT ti.i_item_desc) AS top_item_descriptions
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN sales_hierarchy sh ON ss.ss_item_sk = sh.ss_item_sk
LEFT JOIN top_items ti ON sh.ss_item_sk = ti.i_item_sk AND ti.item_rank <= 10
WHERE ca.ca_state IS NOT NULL
GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
ORDER BY total_sales DESC, c.c_last_name ASC
LIMIT 100;
