
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        0 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT 
        s.ss_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.level + 1
    FROM store_sales s
    JOIN sales_hierarchy sh ON s.ss_customer_sk = sh.c_customer_sk
    JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
),
sales_summary AS (
    SELECT 
        sh.c_customer_sk, 
        sh.c_first_name, 
        sh.c_last_name,
        COUNT(ss_ticket_number) AS total_sales,
        SUM(ss_net_paid_inc_tax) AS total_revenue
    FROM sales_hierarchy sh
    LEFT JOIN store_sales s ON sh.c_customer_sk = s.ss_customer_sk
    GROUP BY sh.c_customer_sk, sh.c_first_name, sh.c_last_name
),
average_revenue AS (
    SELECT 
        AVG(total_revenue) as avg_revenue,
        MAX(total_revenue) as max_revenue
    FROM sales_summary
)
SELECT 
    ss.c_customer_sk,
    ss.c_first_name,
    ss.c_last_name,
    ss.total_sales,
    ss.total_revenue,
    ar.avg_revenue,
    ar.max_revenue,
    CASE 
        WHEN ss.total_revenue IS NULL THEN 'No Revenue'
        WHEN ss.total_revenue > ar.avg_revenue THEN 'Above Average'
        ELSE 'Below Average'
    END AS revenue_status
FROM sales_summary ss
CROSS JOIN average_revenue ar
LEFT JOIN customer_demographics cd ON ss.c_customer_sk = cd.cd_demo_sk
WHERE cd.cd_gender = 'F'
ORDER BY ss.total_revenue DESC
LIMIT 100;
