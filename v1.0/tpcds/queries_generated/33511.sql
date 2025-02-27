
WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           c.c_first_name,
           c.c_last_name,
           cs.ss_ticket_number,
           SUM(cs.ss_sales_price) AS total_sales
    FROM customer c
    JOIN store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    WHERE cs.ss_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, cs.ss_ticket_number

    UNION ALL

    SELECT c.c_customer_sk,
           c.c_customer_id,
           c.c_first_name,
           c.c_last_name,
           sr.sr_ticket_number,
           SUM(sr.sr_return_amt) AS total_sales
    FROM customer c
    JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, sr.sr_ticket_number
),
sales_summary AS (
    SELECT customer_id,
           SUM(total_sales) AS overall_sales
    FROM sales_hierarchy
    GROUP BY customer_id
),
top_customers AS (
    SELECT customer_id,
           overall_sales,
           RANK() OVER (ORDER BY overall_sales DESC) AS sales_rank
    FROM sales_summary
)
SELECT cu.c_first_name,
       cu.c_last_name,
       COALESCE(tc.overall_sales, 0) AS total_sales,
       CASE WHEN tc.sales_rank IS NOT NULL THEN 'Top Customer' ELSE 'Regular Customer' END AS customer_status
FROM customer cu
LEFT JOIN top_customers tc ON cu.c_customer_id = tc.customer_id
WHERE (cu.c_birth_year IS NULL OR cu.c_birth_year >= 1960)
  AND (cu.c_first_name LIKE 'A%' OR cu.c_last_name LIKE 'Z%')
ORDER BY total_sales DESC
LIMIT 100;
