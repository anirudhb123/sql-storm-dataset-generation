
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(ss.ss_ticket_number) AS total_purchases,
        SUM(ss.ss_ext_sales_price) AS total_spent,
        AVG(ss.ss_net_profit) AS average_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_income_band_sk
),
income_analysis AS (
    SELECT 
        id.ib_income_band_sk,
        COUNT(c.customer_id) AS customer_count,
        SUM(c.total_spent) AS total_income,
        AVG(c.average_profit) AS avg_profit_per_customer
    FROM 
        customer_data c
    JOIN 
        household_demographics hd ON c.cd_income_band_sk = hd.hd_income_band_sk
    JOIN 
        income_band id ON hd.hd_income_band_sk = id.ib_income_band_sk
    GROUP BY 
        id.ib_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ia.customer_count,
    ia.total_income,
    ia.avg_profit_per_customer
FROM 
    income_band ib
LEFT JOIN 
    income_analysis ia ON ib.ib_income_band_sk = ia.ib_income_band_sk
ORDER BY 
    ib.ib_income_band_sk;
