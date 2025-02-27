
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month,
        sum(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        sum(ws.ws_ext_discount_amt) AS total_discount,
        sum(ws.ws_net_profit) AS total_profit,
        c.ca_state AS state,
        cd.cd_gender AS customer_gender,
        hd.hd_income_band_sk AS income_band_sk
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        d.d_year = 2023 
    GROUP BY 
        d.d_year, d.d_month_seq, c.ca_state, cd.cd_gender, hd.hd_income_band_sk
),
income_band_summary AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(*) AS customer_count,
        SUM(total_sales) AS total_income 
    FROM 
        sales_summary ss
    JOIN 
        income_band ib ON ss.income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ABS(total_income) AS abs_total_income,
    customer_count
FROM 
    income_band_summary ibs
JOIN 
    income_band ib ON ibs.ib_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    abs_total_income DESC;
