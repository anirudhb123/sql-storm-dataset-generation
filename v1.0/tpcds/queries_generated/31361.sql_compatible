
WITH RECURSIVE sales_hierarchy AS (
    SELECT s_store_sk, s_store_name, 0 AS hierarchy_level
    FROM store
    WHERE s_state = 'CA'
    
    UNION ALL
    
    SELECT s.s_store_sk, s.s_store_name, sh.hierarchy_level + 1
    FROM store s
    JOIN sales_hierarchy sh ON s.s_store_sk = sh.s_store_sk
    WHERE sh.hierarchy_level < 10
),
customer_sales AS (
    SELECT c.c_customer_sk, SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_current_addr_sk IS NOT NULL
    GROUP BY c.c_customer_sk
),
customer_ranked AS (
    SELECT cs.c_customer_sk, cs.total_sales,
           RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM customer_sales cs
),
item_analysis AS (
    SELECT i.i_item_sk, i.i_item_id, 
           COUNT(DISTINCT ws.ws_order_number) AS order_count,
           AVG(ws.ws_sales_price) AS avg_sales_price,
           SUM(ws.ws_ext_sales_price) AS total_revenue
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
),
top_items AS (
    SELECT ia.i_item_id, ia.total_revenue,
           RANK() OVER (ORDER BY ia.total_revenue DESC) AS item_rank
    FROM item_analysis ia
    WHERE ia.order_count > 5
)
SELECT ch.s_store_name,
       c.sales_rank, 
       ti.i_item_id,
       ti.total_revenue,
       ch.hierarchy_level
FROM customer_ranked c
JOIN top_items ti ON c.total_sales > 1000
JOIN sales_hierarchy ch ON ch.s_store_sk IN (
    SELECT DISTINCT ss.s_store_sk
    FROM store_sales ss
    WHERE ss.ss_sales_price > ti.total_revenue
)
WHERE ch.hierarchy_level < 3
ORDER BY ch.s_store_name, c.sales_rank;
