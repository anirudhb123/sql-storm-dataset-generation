
WITH sales_summary AS (
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ss.ss_net_profit) AS avg_net_profit
    FROM 
        store_sales ss
    JOIN 
        date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ss.ss_sold_date_sk, ss.ss_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.total_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases
    FROM 
        sales_summary ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
demographics_summary AS (
    SELECT 
        h.hd_income_band_sk,
        AVG(cs.total_spent) AS avg_spent_per_income_band,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count
    FROM 
        customer_summary cs
    JOIN 
        household_demographics h ON cs.c_customer_sk = h.hd_demo_sk
    GROUP BY 
        h.hd_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ds.avg_spent_per_income_band,
    ds.customer_count
FROM 
    income_band ib
LEFT JOIN 
    demographics_summary ds ON ib.ib_income_band_sk = ds.hd_income_band_sk
ORDER BY 
    ib.ib_income_band_sk;
