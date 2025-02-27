
WITH RECURSIVE top_customers AS (
    SELECT c.c_customer_sk, 
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name, 
           SUM(ss.ss_net_paid) AS total_spent 
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(ss.ss_net_paid) IS NOT NULL
    ORDER BY total_spent DESC
    LIMIT 10
),
sales_data AS (
    SELECT ws.ws_sold_date_sk, 
           d.d_date AS sales_date, 
           w.w_warehouse_name, 
           SUM(ws.ws_ext_sales_price) AS total_sales 
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY ws.ws_sold_date_sk, d.d_date, w.w_warehouse_name
),
average_sales AS (
    SELECT AVG(total_sales) AS avg_sales 
    FROM sales_data
),
ranked_sales AS (
    SELECT sales_date, total_sales, 
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank 
    FROM sales_data
)
SELECT tc.customer_name, 
       COALESCE(rs.total_sales, 0) AS total_web_sales, 
       (SELECT avg_sales FROM average_sales) AS avg_sales,
       CASE 
           WHEN COALESCE(rs.total_sales, 0) > (SELECT avg_sales FROM average_sales) 
           THEN 'Above Average' 
           ELSE 'Below Average' 
       END AS sales_comparison 
FROM top_customers tc
LEFT JOIN ranked_sales rs ON tc.c_customer_sk = rs.sales_date 
WHERE rs.sales_rank <= 5
ORDER BY total_web_sales DESC;
