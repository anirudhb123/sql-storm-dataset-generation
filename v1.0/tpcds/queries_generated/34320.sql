
WITH RECURSIVE sales_hierarchy AS (
    SELECT ss_store_sk, SUM(ss_ext_sales_price) AS total_sales, 1 AS level
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY ss_store_sk
    UNION ALL
    SELECT sh.ss_store_sk, SUM(s.ss_ext_sales_price) + sh.total_sales, sh.level + 1
    FROM sales_hierarchy sh
    JOIN store_sales s ON sh.ss_store_sk = s.ss_store_sk AND sh.level < 5
    WHERE s.ss_sold_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
)
SELECT 
    ca_state,
    SUM(total_sales) AS total_revenue,
    COUNT(DISTINCT ss_store_sk) AS store_count,
    AVG(CASE WHEN total_sales IS NOT NULL THEN total_sales ELSE 0 END) AS avg_sales,
    MAX(total_sales) AS max_store_sales,
    STRING_AGG(DISTINCT i_item_id || ' (' || i_item_desc || ')', ', ') AS top_items_sold
FROM sales_hierarchy sh
JOIN store s ON sh.ss_store_sk = s.s_store_sk
JOIN customer_address ca ON s.s_addr_sk = ca.ca_address_sk
JOIN web_sales ws ON ws.ws_ship_date_sk = (SELECT MAX(ws_ship_date_sk) FROM web_sales)
JOIN item i ON ws.ws_item_sk = i.i_item_sk
WHERE ca.ca_state IS NOT NULL
GROUP BY ca_state
ORDER BY total_revenue DESC
LIMIT 10;
