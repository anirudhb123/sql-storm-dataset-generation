
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    INNER JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
), 
item_sales AS (
    SELECT 
        i.i_item_sk,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_quantity), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_store_sales
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY i.i_item_sk
),
customer_totals AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS net_spent
    FROM customer_hierarchy ch
    LEFT JOIN web_sales ws ON ch.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON ch.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON ch.c_customer_sk = ss.ss_customer_sk
    GROUP BY ch.c_customer_sk, ch.c_first_name, ch.c_last_name
)
SELECT 
    ct.c_customer_sk,
    ct.c_first_name,
    ct.c_last_name,
    COALESCE(its.total_web_sales, 0) AS total_web_sales,
    COALESCE(its.total_catalog_sales, 0) AS total_catalog_sales,
    COALESCE(its.total_store_sales, 0) AS total_store_sales,
    ct.net_spent,
    RANK() OVER (ORDER BY ct.net_spent DESC) AS customer_rank
FROM customer_totals ct
LEFT JOIN item_sales its ON ct.c_customer_sk = its.i_item_sk
WHERE ct.net_spent IS NOT NULL
ORDER BY ct.net_spent DESC
LIMIT 100;
