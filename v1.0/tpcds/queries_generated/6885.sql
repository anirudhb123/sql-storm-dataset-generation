
WITH sales_data AS (
    SELECT
        ws.bill_customer_sk AS customer_sk,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(ws.order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY cd.demo_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        date_dim d ON ws.sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
        AND d.d_month IN (1, 2, 3)
    GROUP BY
        ws.bill_customer_sk, cd.gender, cd.marital_status, cd.education_status
),
top_customers AS (
    SELECT
        customer_sk,
        gender,
        marital_status,
        education_status,
        total_sales,
        order_count
    FROM
        sales_data
    WHERE
        sales_rank <= 10
)
SELECT
    tc.gender,
    tc.marital_status,
    tc.education_status,
    AVG(tc.total_sales) AS avg_sales,
    COUNT(*) AS customer_count
FROM
    top_customers tc
GROUP BY
    tc.gender, tc.marital_status, tc.education_status
ORDER BY
    avg_sales DESC;
