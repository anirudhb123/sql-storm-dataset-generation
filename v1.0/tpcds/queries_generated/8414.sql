
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name || ' ' || c.c_last_name AS customer_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk,
        customer_name
),
demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cs.total_spent,
        cs.total_orders
    FROM 
        customer_demographics cd
    JOIN 
        customer_sales cs ON cd.cd_demo_sk = c.c_current_cdemo_sk
),
income_distribution AS (
    SELECT 
        ib.ib_income_band_sk,
        SUM(CASE WHEN d.total_spent < ib.ib_upper_bound THEN 1 ELSE 0 END) AS count_in_band
    FROM 
        demographics d
    JOIN 
        household_demographics hd ON d.c_customer_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    COUNT(1) AS total_customers,
    SUM(count_in_band) AS customers_in_band
FROM 
    income_distribution ib
JOIN 
    demographics d ON ib.ib_income_band_sk = d.cd_demo_sk
GROUP BY 
    ib.ib_income_band_sk;
