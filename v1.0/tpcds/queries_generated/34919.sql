
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
    HAVING SUM(ws.ws_ext_sales_price) > 1000
),
top_sales AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM sales_hierarchy
)
SELECT 
    th.c_first_name,
    th.c_last_name,
    th.total_sales,
    DATEDIFF(CURRENT_DATE, MAX(wp.wp_creation_date_sk)) AS days_since_creation,
    COALESCE(wb.ib_lower_bound, 0) AS income_lower_bound,
    COALESCE(wb.ib_upper_bound, 0) AS income_upper_bound,
    CASE 
        WHEN th.sales_rank <= 10 THEN 'Top 10'
        ELSE 'Others' 
    END AS sales_category
FROM top_sales th
LEFT JOIN household_demographics hd ON th.c_customer_sk = hd.hd_demo_sk
LEFT JOIN income_band wb ON hd.hd_income_band_sk = wb.ib_income_band_sk
JOIN web_page wp ON th.c_customer_sk = wp.wp_customer_sk 
GROUP BY th.c_first_name, th.c_last_name, th.total_sales, days_since_creation, wb.ib_lower_bound, wb.ib_upper_bound, th.sales_rank
ORDER BY th.total_sales DESC
LIMIT 100;
