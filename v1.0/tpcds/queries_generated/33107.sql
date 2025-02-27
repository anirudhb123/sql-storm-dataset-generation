
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk,
           1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
sales_with_rank AS (
    SELECT ws.ws_order_number, ws.ws_item_sk, ws.ws_sales_price, ws.ws_quantity,
           RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS price_rank,
           DATE_PART('YEAR', d.d_date) AS sales_year
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
store_sales_summary AS (
    SELECT ss_store_sk, SUM(ss_net_paid) AS total_net_sales,
           SUM(ss_quantity) AS total_quantity_sold
    FROM store_sales
    GROUP BY ss_store_sk
),
customer_stats AS (
    SELECT cd.cd_demo_sk, AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
           COUNT(DISTINCT c.c_customer_sk) AS total_customers,
           MAX(cd.cd_dep_count) AS max_dependents
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_demo_sk
)
SELECT c.c_first_name, c.c_last_name, cs.avg_purchase_estimate,
       ss.total_net_sales, ss.total_quantity_sold,
       sh.level, 
       CASE 
           WHEN sh.level > 1 THEN 'Nested'
           ELSE 'Root'
       END AS customer_level
FROM customer_hierarchy sh
JOIN customer_stats cs ON sh.c_current_cdemo_sk = cs.cd_demo_sk
LEFT JOIN store_sales_summary ss ON ss.ss_store_sk = (SELECT s.store_sk FROM store s WHERE s.s_store_id = '1001')
JOIN sales_with_rank swr ON swr.ws_order_number = (
       SELECT ws.ws_order_number
       FROM web_sales ws
       WHERE ws.ws_item_sk = (
           SELECT i.i_item_sk
           FROM item i
           WHERE i.i_product_name ILIKE '%gadget%'
           LIMIT 1
       )
       LIMIT 1
)
WHERE cs.avg_purchase_estimate IS NOT NULL
AND ss.total_net_sales > 1000.00
ORDER BY cs.avg_purchase_estimate DESC, ss.total_net_sales DESC;
