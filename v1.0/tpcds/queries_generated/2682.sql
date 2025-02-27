
WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT
        c.*,
        cd.cd_gender,
        cd.cd_income_band_sk
    FROM
        customer_sales c
    JOIN
        customer_demographics cd ON c.c_customer_sk = cd.cd_demo_sk
    WHERE
        c.sales_rank <= 10
),
income_summary AS (
    SELECT
        ib.ib_income_band_sk,
        COUNT(tc.c_customer_sk) AS customer_count,
        SUM(tc.total_sales) AS total_income
    FROM
        top_customers tc
    LEFT JOIN
        household_demographics hd ON tc.cd_income_band_sk = hd.hd_income_band_sk
    LEFT JOIN
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY
        ib.ib_income_band_sk
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ISNULL(is.customer_count, 0) AS customer_count,
    ISNULL(is.total_income, 0) AS total_income,
    ISNULL(is.total_income, 0) / NULLIF(ISNULL(is.customer_count, 0), 0) AS avg_income_per_customer
FROM
    income_band ib
LEFT JOIN
    income_summary is ON ib.ib_income_band_sk = is.ib_income_band_sk
ORDER BY
    ib.ib_income_band_sk;
