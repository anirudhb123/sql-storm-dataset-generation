
WITH revenue_per_customer AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_revenue
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.total_revenue,
        DENSE_RANK() OVER (ORDER BY r.total_revenue DESC) AS revenue_rank
    FROM 
        revenue_per_customer r
    WHERE 
        r.total_revenue IS NOT NULL AND r.total_revenue > (SELECT AVG(total_revenue) FROM revenue_per_customer)
),
customer_demographics_info AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
customer_info AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        hvc.total_revenue,
        cdi.cd_gender,
        cdi.cd_marital_status,
        cdi.cd_education_status,
        cdi.hd_income_band_sk,
        cdi.hd_buy_potential
    FROM 
        high_value_customers hvc
    JOIN 
        customer_demographics_info cdi ON hvc.c_customer_sk = cdi.cd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.total_revenue,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = ci.c_customer_sk AND ss.ss_sold_date_sk BETWEEN 20230101 AND 20231231) AS store_purchases,
    (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_ship_date_sk = (SELECT MAX(ws1.ws_ship_date_sk) FROM web_sales ws1 WHERE ws1.ws_bill_customer_sk = ci.c_customer_sk)) AS recent_web_sales,
    COALESCE((SELECT MAX(ws_net_profit) FROM web_sales WHERE ws_bill_customer_sk = ci.c_customer_sk), 0) AS max_web_profit
FROM 
    customer_info ci
WHERE 
    ci.hd_income_band_sk IN (SELECT ib_income_band_sk FROM income_band WHERE ib_upper_bound > 100000)
ORDER BY 
    ci.total_revenue DESC
LIMIT 100
OFFSET 0;
