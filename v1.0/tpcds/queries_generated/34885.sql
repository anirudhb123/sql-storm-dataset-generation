
WITH RECURSIVE sales_dates AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_date >= '2022-01-01'
    UNION ALL
    SELECT d.d_date_sk, d.d_date
    FROM date_dim d
    JOIN sales_dates sd ON d.d_date_sk = sd.d_date_sk + 1
),
top_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(ss.ss_net_paid) AS total_spent
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_sold_date_sk IN (SELECT d_date_sk FROM sales_dates)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY total_spent DESC
    LIMIT 10
),
customer_demographics AS (
    SELECT cd.cc_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, 
           cd.cd_purchase_estimate, cd.cd_credit_rating, cd.cd_dep_count
    FROM customer_demographics cd
    JOIN top_customers tc ON cd.cd_demo_sk = tc.c_customer_sk
),
store_info AS (
    SELECT s.s_store_sk, s.s_store_name, AVG(ss.ss_net_paid) AS avg_sales
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk, s.s_store_name
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    si.s_store_name,
    si.avg_sales,
    CASE 
        WHEN cd.cd_purchase_estimate > 1000 THEN 'High spender' 
        WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Mid spender' 
        ELSE 'Low spender' 
    END AS spending_category
FROM top_customers tc
JOIN customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
JOIN store_info si ON cd.cd_demo_sk = si.s_store_sk
ORDER BY tc.total_spent DESC, si.avg_sales DESC;
