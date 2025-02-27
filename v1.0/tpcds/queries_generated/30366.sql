
WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_customer_sk, c.c_customer_id, s.ss_ticket_number, s.ss_sales_price, s.ss_quantity,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY s.ss_sold_date_sk DESC) AS rn
    FROM customer c
    JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE s.ss_sales_price > 20.00
    UNION ALL
    SELECT c.c_customer_sk, c.c_customer_id, s.ss_ticket_number, s.ss_sales_price * 0.9 AS discount_price, s.ss_quantity
    FROM customer c
    JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    JOIN sales_hierarchy sh ON sh.c_customer_id = c.c_customer_id
    WHERE sh.rn < 5
),
ranked_sales AS (
    SELECT customer_id, SUM(ss_sales_price) AS total_sales, COUNT(ss_ticket_number) AS total_tickets
    FROM sales_hierarchy
    GROUP BY customer_id
),
avg_sales AS (
    SELECT AVG(total_sales) AS avg_total_sales FROM ranked_sales
)
SELECT r.customer_id, r.total_sales, r.total_tickets,
       CASE
           WHEN r.total_sales > (SELECT avg_total_sales FROM avg_sales) THEN 'Above Average'
           ELSE 'Below Average'
       END AS performance,
       (SELECT COUNT(*) FROM customer WHERE c_birth_year = 1980) AS count_birth_year_1980,
       COALESCE(NULLIF(r.total_sales - 1000, 0), 0) AS adjusted_sales
FROM ranked_sales r
ORDER BY r.total_sales DESC
LIMIT 10;
