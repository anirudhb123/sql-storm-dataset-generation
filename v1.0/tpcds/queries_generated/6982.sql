
WITH Recent_Customers AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_first_shipto_date_sk >= (
            SELECT
                MAX(d.d_date_sk)
            FROM
                date_dim d
            WHERE
                d.d_date BETWEEN DATEADD(YEAR, -1, GETDATE()) AND GETDATE()
        )
    GROUP BY
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
Top_Income_Brackets AS (
    SELECT
        hd.hd_income_band_sk,
        COUNT(DISTINCT rc.c_customer_id) AS customer_count,
        SUM(rc.total_net_profit) AS income_bracket_profit
    FROM
        household_demographics hd
    JOIN
        Recent_Customers rc ON hd.hd_demo_sk = rc.c_customer_sk
    GROUP BY
        hd.hd_income_band_sk
    ORDER BY
        income_bracket_profit DESC
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    t.customer_count,
    t.income_bracket_profit
FROM
    income_band ib
LEFT JOIN
    Top_Income_Brackets t ON ib.ib_income_band_sk = t.hd_income_band_sk
WHERE
    t.customer_count > 0
ORDER BY
    ib.ib_lower_bound;
