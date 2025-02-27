
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year,
        1 AS level
    FROM customer c
    WHERE c.c_birth_year >= 1980
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year,
        ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_cdemo_sk
    WHERE ch.level < 5
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        ch.c_customer_sk, 
        ch.c_first_name, 
        ch.c_last_name, 
        ss.total_sales,
        ss.order_count,
        DENSE_RANK() OVER (ORDER BY ss.total_sales DESC) as sales_rank
    FROM customer_hierarchy ch
    LEFT JOIN sales_summary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_sales, 0) AS total_sales,
    COALESCE(tc.order_count, 0) AS order_count,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    CONCAT(tc.c_first_name, ' ', tc.c_last_name) AS full_name
FROM top_customers tc
WHERE tc.order_count > 0
  AND (tc.total_sales IS NOT NULL OR tc.order_count IS NOT NULL)
ORDER BY tc.total_sales DESC 
LIMIT 100;
