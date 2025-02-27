
WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022) AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(ws.ws_ext_sales_price) > 1000
    UNION ALL
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name,
           sh.total_sales * 1.1
    FROM customer ch
    JOIN sales_hierarchy sh ON ch.c_customer_sk = sh.c_customer_sk
)
SELECT 
    ca.ca_state, 
    SUM(sh.total_sales) AS state_sales,
    COUNT(DISTINCT sh.c_customer_sk) AS unique_customers,
    COALESCE(INDEX(avg_sh.sales_per_customer), 0) AS avg_sales_per_customer
FROM sales_hierarchy sh
JOIN customer_address ca ON sh.c_customer_sk = ca.ca_address_sk
LEFT JOIN (
    SELECT sh.c_customer_sk, 
           AVG(sh.total_sales) AS sales_per_customer
    FROM sales_hierarchy sh
    GROUP BY sh.c_customer_sk
) avg_sh ON avg_sh.c_customer_sk = sh.c_customer_sk
WHERE ca.ca_state IS NOT NULL
GROUP BY ca.ca_state
HAVING SUM(sh.total_sales) > (SELECT AVG(total_sales) FROM sales_hierarchy)
ORDER BY state_sales DESC
LIMIT 10;
