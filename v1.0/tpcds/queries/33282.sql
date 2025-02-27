
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 
           c_current_cdemo_sk, 0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2452000 AND 2455000
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        ROW_NUMBER() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM sales_summary s
    JOIN customer c ON s.c_customer_sk = c.c_customer_sk
    WHERE s.total_sales > 1000
),
recent_customers AS (
    SELECT 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    FROM customer c
    WHERE c.c_first_shipto_date_sk = (
        SELECT MAX(c_first_shipto_date_sk)
        FROM customer
    )
),
joined_data AS (
    SELECT 
        ch.c_customer_sk AS hierarchy_cust_sk,
        s.total_sales,
        r.c_first_name AS recently_active_first_name,
        r.c_last_name AS recently_active_last_name,
        CASE 
            WHEN t.sales_rank IS NOT NULL THEN 'Top Customer' 
            ELSE 'Regular Customer' 
        END AS customer_type
    FROM customer_hierarchy ch
    LEFT JOIN sales_summary s ON ch.c_customer_sk = s.c_customer_sk
    LEFT JOIN recent_customers r ON ch.c_customer_sk = r.c_customer_sk
    LEFT JOIN top_customers t ON ch.c_customer_sk = t.c_customer_sk
)
SELECT 
    jd.hierarchy_cust_sk,
    jd.total_sales,
    jd.recently_active_first_name,
    jd.recently_active_last_name,
    jd.customer_type
FROM joined_data jd
WHERE jd.total_sales IS NOT NULL
ORDER BY jd.total_sales DESC,
         jd.hierarchy_cust_sk;
