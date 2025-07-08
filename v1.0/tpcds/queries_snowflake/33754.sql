
WITH sales_hierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        d.d_year, 
        SUM(ss.ss_net_profit) AS total_sales
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2023
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year

    UNION ALL

    SELECT 
        sh.c_customer_sk,
        sh.c_first_name, 
        sh.c_last_name,
        d.d_year,
        sh.total_sales + COALESCE(SUM(ss.ss_net_profit), 0)
    FROM sales_hierarchy sh
    JOIN store_sales ss ON sh.c_customer_sk = ss.ss_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = sh.d_year + 1
    GROUP BY sh.c_customer_sk, sh.c_first_name, sh.c_last_name, d.d_year, sh.total_sales
),
ranked_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name, 
        c.c_last_name,
        s.total_sales,
        DENSE_RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM customer c
    JOIN (SELECT c_customer_sk, total_sales FROM sales_hierarchy) s 
    ON c.c_customer_sk = s.c_customer_sk
),
top_customers AS (
    SELECT * FROM ranked_sales WHERE sales_rank <= 10
)
SELECT 
    CONCAT(tc.c_first_name, ' ', tc.c_last_name) AS customer_name,
    tc.total_sales,
    CASE 
        WHEN tc.total_sales IS NULL THEN 'No Sales'
        WHEN tc.total_sales > 10000 THEN 'Gold'
        WHEN tc.total_sales <= 10000 AND tc.total_sales > 5000 THEN 'Silver'
        ELSE 'Bronze' 
    END AS customer_tier
FROM top_customers tc
LEFT JOIN customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
WHERE cd.cd_marital_status = 'M' AND cd.cd_gender = 'F'
ORDER BY tc.total_sales DESC;
