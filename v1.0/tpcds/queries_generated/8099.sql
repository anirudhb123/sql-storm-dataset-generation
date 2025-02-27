
WITH ranked_sales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_income_band_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
        AND d.d_moy IN (1, 2, 3, 4) -- First four months of the year
    GROUP BY
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
top_customers AS (
    SELECT
        customer_id,
        total_sales,
        order_count,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk
    FROM
        ranked_sales
    WHERE
        rank <= 10
)
SELECT
    tc.customer_id,
    tc.total_sales,
    tc.order_count,
    cd.ib_lower_bound,
    cd.ib_upper_bound,
    tc.cd_gender,
    tc.cd_marital_status
FROM
    top_customers tc
JOIN income_band cd ON tc.cd_income_band_sk = cd.ib_income_band_sk
ORDER BY
    tc.total_sales DESC;
