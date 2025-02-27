
WITH customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        d.d_year >= 2020
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
),
customer_ranked AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_year ORDER BY total_spent DESC) AS rank
    FROM 
        customer_info
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cr.d_year,
    cr.cd_gender,
    cr.cd_marital_status,
    cr.cd_education_status,
    cr.ib_lower_bound,
    cr.ib_upper_bound,
    cr.total_orders,
    cr.total_spent
FROM 
    customer_ranked cr
WHERE 
    cr.rank <= 10
ORDER BY 
    cr.d_year, 
    cr.rank;
