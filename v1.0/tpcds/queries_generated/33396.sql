
WITH RECURSIVE sales_hierarchy AS (
    SELECT s_store_sk, s_store_name, s_sales, 1 AS level
    FROM store
    JOIN (
        SELECT ss_store_sk, SUM(ss_net_profit) AS s_sales
        FROM store_sales
        WHERE ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
        GROUP BY ss_store_sk
    ) AS sales_summary ON store.s_store_sk = sales_summary.ss_store_sk

    UNION ALL

    SELECT sh.s_store_sk, sh.s_store_name, SUM(sales_total.s_sales), level + 1
    FROM sales_hierarchy sh
    JOIN (
        SELECT ss_store_sk, ss_net_profit AS s_sales
        FROM store_sales
        WHERE ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    ) AS sales_total ON sales_total.ss_store_sk = sh.s_store_sk
    GROUP BY sh.s_store_sk, sh.s_store_name, level
)

SELECT c.c_customer_id, c.c_first_name, c.c_last_name, 
       ARRAY_AGG(DISTINCT a.ca_city) AS cities,
       MAX(sales_hierarchy.s_sales) AS highest_sale,
       AVG(sales_hierarchy.s_sales) FILTER (WHERE sales_hierarchy.level = 2) AS avg_sales_level_2
FROM customer c
LEFT JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN sales_hierarchy ON sales_hierarchy.s_store_sk IN (
    SELECT ss_store_sk
    FROM store_sales
    WHERE ss_customer_sk = c.c_customer_sk
)
WHERE c.c_birth_country IS NOT NULL
  AND (c.c_preferred_cust_flag IS NULL OR c.c_preferred_cust_flag = 'Y')
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
HAVING COUNT(DISTINCT a.ca_city) > 1
ORDER BY highest_sale DESC
LIMIT 10;
