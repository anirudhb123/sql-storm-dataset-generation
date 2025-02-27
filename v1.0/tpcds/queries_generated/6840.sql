
WITH top_customers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, SUM(ss_net_paid) AS total_spent
    FROM customer
    JOIN store_sales ON c_customer_sk = ss_customer_sk
    GROUP BY c_customer_sk, c_first_name, c_last_name
    ORDER BY total_spent DESC
    LIMIT 10
),
sales_summary AS (
    SELECT d_year, SUM(ss_ext_sales_price) AS total_sales, COUNT(DISTINCT ss_ticket_number) AS transaction_count
    FROM store_sales
    JOIN date_dim ON ss_sold_date_sk = d_date_sk
    WHERE d_year >= 2020
    GROUP BY d_year
),
avg_sales AS (
    SELECT d_year, AVG(total_sales) AS avg_sales
    FROM sales_summary
    GROUP BY d_year
)
SELECT 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.total_spent,
    ss.total_sales,
    ss.transaction_count,
    as.avg_sales
FROM top_customers tc
JOIN sales_summary ss ON tc.customer_sk = ss.customer_sk
JOIN avg_sales as ON ss.d_year = as.d_year
WHERE ss.total_sales > as.avg_sales
ORDER BY tc.total_spent DESC, ss.total_sales DESC;
