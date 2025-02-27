
WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(ws.ws_ext_sales_price) AS total_sales, 
           1 AS hierarchy_level
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name

    UNION ALL

    SELECT sh.c_customer_sk, sh.c_first_name, sh.c_last_name, 
           sh.total_sales + SUM(ws.ws_ext_sales_price) AS total_sales,
           sh.hierarchy_level + 1
    FROM sales_hierarchy sh
    LEFT JOIN web_sales ws ON sh.c_customer_sk = ws.ws_bill_customer_sk
    WHERE sh.hierarchy_level < 3 
    GROUP BY sh.c_customer_sk, sh.c_first_name, sh.c_last_name, sh.total_sales, sh.hierarchy_level
),
customer_ranks AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           ROW_NUMBER() OVER (PARTITION BY c.c_birth_month ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_month
)

SELECT s.c_customer_sk, s.c_first_name, s.c_last_name, 
       COALESCE(s.total_sales, 0) AS total_sales,
       coalesce(r.rank, 99) AS sales_rank
FROM sales_hierarchy s
FULL OUTER JOIN customer_ranks r ON s.c_customer_sk = r.c_customer_sk
WHERE (s.total_sales > 10000 OR r.rank <= 10)
ORDER BY s.total_sales DESC NULLS LAST, r.rank ASC
