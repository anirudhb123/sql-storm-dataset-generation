
WITH RECURSIVE sales_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_year, 
           CAST(NULL AS INTEGER) AS parent_id, 
           ROW_NUMBER() OVER (ORDER BY c_customer_sk) AS level
    FROM customer
    WHERE c_birth_year >= 1980
    
    UNION ALL

    SELECT s.ss_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_year, 
           sh.c_customer_sk AS parent_id, 
           sh.level + 1 AS level
    FROM store_sales s
    JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
    JOIN sales_hierarchy sh ON c.c_customer_sk = sh.c_customer_sk
    WHERE s.ss_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
)
SELECT sh.c_first_name, sh.c_last_name, COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
       SUM(s.ss_net_paid_inc_tax) AS total_revenue,
       DENSE_RANK() OVER (PARTITION BY sh.level ORDER BY SUM(s.ss_net_paid_inc_tax) DESC) AS revenue_rank,
       COALESCE(MAX(c.c_email_address), 'No Email') AS email_info
FROM sales_hierarchy sh
LEFT JOIN store_sales s ON sh.c_customer_sk = s.ss_customer_sk
LEFT JOIN customer c ON sh.c_customer_sk = c.c_customer_sk
GROUP BY sh.c_first_name, sh.c_last_name, sh.level
HAVING COUNT(DISTINCT s.ss_ticket_number) > 5
ORDER BY sh.level, total_revenue DESC
LIMIT 100
OFFSET 0;
