
WITH RECURSIVE sales_hierarchy AS (
    SELECT ss_store_sk, SUM(ss_net_profit) AS total_profit
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2452018 AND 2452025
    GROUP BY ss_store_sk
    UNION ALL
    SELECT s.s_store_sk, SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN sales_hierarchy sh ON s.s_store_sk = sh.ss_store_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2452018 AND 2452025
    GROUP BY s.s_store_sk
),
customer_sales AS (
    SELECT c.c_customer_sk, SUM(ws.ws_net_profit) AS total_web_profit
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY c.c_customer_sk
),
item_sales AS (
    SELECT i.i_item_sk, AVG(ws.ws_sales_price) AS avg_sales_price
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk
),
combined_sales AS (
    SELECT ch.ss_store_sk,
           ch.total_profit,
           cs.total_web_profit,
           (ch.total_profit + COALESCE(cs.total_web_profit, 0)) AS grand_total_profit
    FROM sales_hierarchy ch
    LEFT JOIN customer_sales cs ON ch.ss_store_sk = cs.c_customer_sk
)
SELECT cb.ss_store_sk,
       cb.total_profit,
       cb.total_web_profit,
       cb.grand_total_profit,
       ws.partitioned_total_net_profit
FROM combined_sales cb
JOIN (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_net_profit) AS partitioned_total_net_profit,
           ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rn
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
) ws ON cb.ss_store_sk = ws.ws_item_sk
WHERE cb.grand_total_profit > 1000
ORDER BY cb.grand_total_profit DESC
LIMIT 10;
