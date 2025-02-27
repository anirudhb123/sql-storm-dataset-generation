
WITH sales_summary AS (
    SELECT 
        ws.sold_date_sk,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_net_profit,
        AVG(ws.net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.sold_date_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        DENSE_RANK() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY c.c_customer_sk) AS income_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
average_income AS (
    SELECT 
        ib.ib_income_band_sk,
        AVG(ib.ib_upper_bound) AS avg_income_upper_bound
    FROM 
        income_band ib
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    ci.first_name,
    ci.last_name,
    ci.gender,
    ci.marital_status,
    ib.ib_income_band_sk,
    ai.avg_income_upper_bound,
    ss.total_orders,
    ss.total_net_profit,
    ss.avg_order_value
FROM 
    customer_info ci
JOIN 
    sales_summary ss ON ci.c_customer_sk IN (
        SELECT
            ws_bill_customer_sk
        FROM
            web_sales
        GROUP BY
            ws_bill_customer_sk
        HAVING
            SUM(ws_net_profit) > 1000
    )
JOIN 
    average_income ai ON ci.hd_income_band_sk = ai.ib_income_band_sk
LEFT JOIN 
    income_band ib ON ci.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    ci.income_rank <= 10
ORDER BY 
    ss.total_net_profit DESC
LIMIT 100;
