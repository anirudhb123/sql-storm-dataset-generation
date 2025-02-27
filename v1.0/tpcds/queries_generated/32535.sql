
WITH RECURSIVE sales_hierarchy AS (
    SELECT s_store_sk, s_store_name, s_number_employees, s_floor_space, 
           ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY s_floor_space DESC) AS rn
    FROM store
    WHERE s_number_employees IS NOT NULL
    UNION ALL
    SELECT sh.s_store_sk, sh.s_store_name, sh.s_number_employees, 
           sh.s_floor_space, 
           ROW_NUMBER() OVER (PARTITION BY sh.s_store_sk ORDER BY sh.s_floor_space DESC)
    FROM sales_hierarchy sh
    JOIN store s ON sh.s_store_sk = s.s_store_sk 
    WHERE sh.rn < 5
),
customer_sales AS (
    SELECT c.c_customer_id, c.c_first_name, c.c_last_name, 
           SUM(ws.ws_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT c.c_customer_id, c.c_first_name, c.c_last_name, total_sales,
           CASE 
               WHEN total_sales > 1000 THEN 'High Value'
               WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
               ELSE 'Low Value'
           END AS customer_value
    FROM customer_sales c
    WHERE total_sales IS NOT NULL
)

SELECT sh.s_store_name, sh.s_number_employees, sh.s_floor_space, 
       hvc.customer_value, COUNT(hvc.c_customer_id) AS customer_count
FROM sales_hierarchy sh
LEFT JOIN high_value_customers hvc ON sh.s_store_sk = 
    (SELECT ss.ss_store_sk FROM store_sales ss 
     WHERE ss.ss_ticket_number IN (SELECT MAX(ss2.ss_ticket_number) 
                                   FROM store_sales ss2 
                                   WHERE ss2.ss_store_sk = sh.s_store_sk))
GROUP BY sh.s_store_name, sh.s_number_employees, sh.s_floor_space, hvc.customer_value
HAVING COUNT(hvc.c_customer_id) > 0
ORDER BY sh.s_floor_space DESC, customer_count DESC;
