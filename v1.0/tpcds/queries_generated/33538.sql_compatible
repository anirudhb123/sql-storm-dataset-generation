
WITH RECURSIVE top_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(ss.ss_net_paid) AS total_spent
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(ss.ss_net_paid) > 1000
),
customer_demographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
    FROM customer_demographics cd
    WHERE cd.cd_income_band_sk IN (SELECT ib.ib_income_band_sk FROM income_band ib WHERE ib.ib_lower_bound >= 50000)
),
date_sales AS (
    SELECT d.d_year, SUM(ws.ws_net_sales) AS total_sales
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_year BETWEEN 2021 AND 2023
    GROUP BY d.d_year
),
store_revenue AS (
    SELECT s.s_store_sk, SUM(ss.ss_net_paid) AS store_revenue
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk
),
ranked_stores AS (
    SELECT s.s_store_sk, s.s_store_name, sr.store_revenue, RANK() OVER (ORDER BY sr.store_revenue DESC) AS revenue_rank
    FROM store s
    JOIN store_revenue sr ON s.s_store_sk = sr.s_store_sk
)
SELECT tc.c_customer_sk, tc.c_first_name, tc.c_last_name, cd.cd_gender, cd.cd_marital_status,
       ds.d_year, ds.total_sales,
       rs.s_store_name, rs.store_revenue, rs.revenue_rank
FROM top_customers tc
JOIN customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
CROSS JOIN date_sales ds
JOIN ranked_stores rs ON ds.total_sales > 5000 AND rs.revenue_rank <= 5
ORDER BY tc.total_spent DESC, ds.d_year;
