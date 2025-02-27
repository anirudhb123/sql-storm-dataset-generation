
WITH sales_data AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        d.d_year,
        d.d_month_seq
    FROM store_sales AS cs
    JOIN store AS s ON cs.ss_store_sk = s.s_store_sk
    JOIN customer AS c ON cs.ss_customer_sk = c.c_customer_sk
    JOIN date_dim AS d ON cs.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY s.s_store_sk, s.s_store_name, c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq
),
customer_analysis AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT sa.c_customer_id) AS customer_count,
        SUM(sa.total_quantity) AS total_quantity,
        SUM(sa.total_sales) AS total_sales
    FROM sales_data AS sa
    JOIN customer_demographics AS cd ON sa.c_customer_id = cd.cd_demo_sk
    GROUP BY cd.cd_gender
)
SELECT 
    ca.cd_gender,
    ca.customer_count,
    ca.total_quantity,
    ca.total_sales,
    ca.total_sales / NULLIF(ca.total_quantity, 0) AS avg_sales_per_customer
FROM customer_analysis AS ca
ORDER BY total_sales DESC;
