
WITH sales_summary AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        d.d_year,
        d.d_month_seq
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        c.c_customer_id, d.d_year, d.d_month_seq
),
demographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        SUM(ss.total_sales) AS total_sales_by_demographic
    FROM
        customer_demographics cd
    JOIN
        (SELECT DISTINCT c.c_current_cdemo_sk, cs.total_sales
         FROM customer c
         JOIN sales_summary cs ON c.c_customer_id = cs.c_customer_id) sales ON cd.cd_demo_sk = sales.c_current_cdemo_sk
    GROUP BY
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
income_summary AS (
    SELECT
        ib.ib_income_band_sk,
        SUM(d.total_sales_by_demographic) AS total_sales_by_income
    FROM
        demographics d
    JOIN
        income_band ib ON d.cd_income_band_sk = ib.ib_income_band_sk
    GROUP BY
        ib.ib_income_band_sk
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    is.total_sales_by_income
FROM
    income_band ib
LEFT JOIN
    income_summary is ON ib.ib_income_band_sk = is.ib_income_band_sk
ORDER BY
    ib.ib_income_band_sk;
