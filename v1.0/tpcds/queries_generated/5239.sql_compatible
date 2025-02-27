
WITH customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        d.d_year AS year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2018 AND 2023
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, d.d_year
),
high_value_customers AS (
    SELECT
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.total_sales,
        ci.purchase_count,
        RANK() OVER (PARTITION BY ci.year ORDER BY ci.total_sales DESC) AS sales_rank
    FROM customer_info ci
)
SELECT
    hvc.year,
    COUNT(*) AS high_value_count,
    AVG(hvc.total_sales) AS avg_sales,
    AVG(hvc.purchase_count) AS avg_purchases,
    STRING_AGG(CONCAT(hvc.c_first_name, ' ', hvc.c_last_name), ', ') AS top_customers
FROM high_value_customers hvc
WHERE hvc.sales_rank <= 10
GROUP BY hvc.year
ORDER BY hvc.year;
