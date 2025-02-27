
WITH sales_data AS (
    SELECT
        s.ss_store_sk,
        s.ss_item_sk,
        SUM(s.ss_quantity) AS total_quantity,
        SUM(s.ss_ext_sales_price) AS total_sales,
        SUM(s.ss_ext_tax) AS total_tax,
        d.d_year,
        d.d_quarter_seq,
        d.d_month_seq
    FROM
        store_sales s
    JOIN
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2022
    GROUP BY
        s.ss_store_sk, s.ss_item_sk, d.d_year, d.d_quarter_seq, d.d_month_seq
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_value_customers AS (
    SELECT
        c.c_customer_sk,
        SUM(sd.total_sales) AS total_spent
    FROM
        sales_data sd
    JOIN
        customer_info c ON sd.ss_customer_sk = c.c_customer_sk
    GROUP BY
        c.c_customer_sk
    HAVING
        SUM(sd.total_sales) > 1000
)
SELECT
    SUM(sd.total_sales) AS grand_total_sales,
    AVG(sd.total_sales) AS average_sales_per_store,
    COUNT(DISTINCT hvc.c_customer_sk) AS high_value_customer_count,
    d.d_month_seq AS month,
    d.d_quarter_seq AS quarter
FROM
    sales_data sd
JOIN
    high_value_customers hvc ON sd.ss_store_sk = hvc.c_customer_sk
JOIN
    date_dim d ON sd.d_year = d.d_year
GROUP BY
    d.d_month_seq, d.d_quarter_seq
ORDER BY
    d.d_quarter_seq, d.d_month_seq;
