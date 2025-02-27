
WITH sales_summary AS (
    SELECT
        ws.bill_customer_sk,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        SUM(ws.ext_sales_price) AS total_sales,
        SUM(ws.ext_discount_amt) AS total_discount,
        d.year AS sale_year,
        d.month AS sale_month
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.sold_date_sk = d.d_date_sk
    WHERE
        d.year BETWEEN 2021 AND 2023
    GROUP BY
        ws.bill_customer_sk, d.year, d.month
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        c.first_name,
        c.last_name,
        cd.gender,
        cd.education_status,
        COALESCE(SUM(ss.total_sales), 0) AS total_sales,
        COALESCE(SUM(ss.total_discount), 0) AS total_discount,
        COUNT(ss.total_orders) AS order_count
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        sales_summary ss ON c.c_customer_sk = ss.bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.first_name, c.last_name, cd.gender, cd.education_status
)
SELECT
    cs.c_customer_sk,
    cs.first_name,
    cs.last_name,
    cs.gender,
    cs.education_status,
    cs.total_sales,
    cs.total_discount,
    cs.order_count,
    ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
FROM
    customer_summary cs
WHERE
    cs.order_count > 0
ORDER BY
    cs.total_sales DESC
LIMIT 100;
