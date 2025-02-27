
WITH RECURSIVE sales_by_customer AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(ws.ws_order_number) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, sbc.total_sales, sbc.order_count
    FROM sales_by_customer sbc
    INNER JOIN customer c ON sbc.c_customer_sk = c.c_customer_sk
    WHERE sbc.sales_rank <= 10
),
store_sales_summary AS (
    SELECT ss.s_store_sk, SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM store_sales ss
    GROUP BY ss.s_store_sk
),
sales_by_state AS (
    SELECT ca.ca_state, SUM(ss.ss_ext_sales_price) AS state_sales
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON s.s_store_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
),
final_summary AS (
    SELECT tc.c_first_name, tc.c_last_name, 
           tc.total_sales AS customer_sales, 
           sss.total_store_sales, 
           sbs.state_sales,
           CASE
               WHEN sbs.state_sales IS NULL THEN 'No Sales'
               WHEN tc.total_sales > sss.total_store_sales THEN 'Above Average'
               ELSE 'Below Average' 
           END AS sales_comparison
    FROM top_customers tc
    LEFT JOIN store_sales_summary sss ON sss.total_store_sales > 0
    LEFT JOIN sales_by_state sbs ON sbs.state_sales > 0
)
SELECT f.c_first_name, f.c_last_name, f.customer_sales, f.total_store_sales, f.state_sales, f.sales_comparison
FROM final_summary f
WHERE f.customer_sales IS NOT NULL
ORDER BY f.customer_sales DESC;
