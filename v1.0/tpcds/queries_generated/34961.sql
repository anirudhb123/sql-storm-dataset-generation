
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_spent,
        1 AS level
    FROM
        customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        total_spent > 1000

    UNION ALL

    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_spent,
        h.level + 1
    FROM 
        SalesHierarchy h
    JOIN customer ch ON h.c_customer_sk = ch.c_current_cdemo_sk
    LEFT JOIN store_sales ss ON ch.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        ch.c_customer_sk, ch.c_first_name, ch.c_last_name, h.level
),
BestCustomers AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.total_spent,
        RANK() OVER (ORDER BY sh.total_spent DESC) AS rank
    FROM 
        SalesHierarchy sh
)
SELECT 
    b.c_customer_sk,
    b.c_first_name,
    b.c_last_name,
    b.total_spent,
    CASE 
        WHEN b.rank <= 10 THEN 'Top 10 Customer'
        ELSE 'Regular Customer'
    END AS customer_category,
    COALESCE(wp.wp_url, 'No URL Found') AS website_url
FROM 
    BestCustomers b
LEFT JOIN web_page wp ON b.c_customer_sk = wp.wp_customer_sk
WHERE 
    b.rank <= 20 OR wp.wp_url IS NOT NULL
ORDER BY 
    customer_category, total_spent DESC;
