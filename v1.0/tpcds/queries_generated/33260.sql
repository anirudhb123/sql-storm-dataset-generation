
WITH RECURSIVE sales_hierarchy AS (
    SELECT w.warehouse_name,
           SUM(ss.net_profit) AS total_net_profit,
           0 AS level,
           w.warehouse_sk
    FROM warehouse w
    JOIN store s ON w.warehouse_sk = s.s_store_sk
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE ss.ss_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY w.warehouse_name, w.warehouse_sk
    UNION ALL
    SELECT wh.warehouse_name,
           SUM(ss.net_profit),
           sh.level + 1,
           wh.warehouse_sk
    FROM warehouse wh
    JOIN sales_hierarchy sh ON sh.warehouse_sk = wh.warehouse_sk
    JOIN store s ON wh.warehouse_sk = s.s_store_sk
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE ss.ss_net_paid > 0
)
SELECT sh.warehouse_name,
       sh.total_net_profit,
       RANK() OVER (ORDER BY sh.total_net_profit DESC) AS profit_rank,
       CASE WHEN sh.total_net_profit IS NULL THEN 'No Sales' 
            ELSE 'Sales Achieved' END AS sales_status
FROM sales_hierarchy sh
WHERE sh.level = 0
ORDER BY sh.total_net_profit DESC
LIMIT 10
UNION ALL
SELECT DISTINCT ca.ca_city AS missing_city,
       NULL AS total_net_profit,
       NULL AS profit_rank,
       'No Sales' AS sales_status
FROM customer_address ca
WHERE ca.ca_city IS NOT NULL
  AND ca.ca_city NOT IN (SELECT DISTINCT w.warehouse_name
                         FROM warehouse w
                         JOIN store s ON w.warehouse_sk = s.s_store_sk
                         JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
                         WHERE ss.ss_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim));
