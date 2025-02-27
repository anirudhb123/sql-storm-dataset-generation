
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_profit) AS avg_profit,
        RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS spend_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1980
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
IncomeStats AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        AVG(cs.total_spent) AS avg_customer_spent
    FROM 
        household_demographics hd
    LEFT JOIN 
        CustomerStats cs ON hd.hd_demo_sk = cs.c_customer_id
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(is.customer_count, 0) AS customer_count,
    COALESCE(is.avg_customer_spent, 0.00) AS avg_spent,
    CASE 
        WHEN COALESCE(is.customer_count, 0) = 0 THEN 'No customers'
        ELSE CONCAT('Income Band: ', ib.ib_lower_bound, ' - ', ib.ib_upper_bound)
    END AS income_band_description
FROM 
    income_band ib
LEFT JOIN 
    IncomeStats is ON ib.ib_income_band_sk = is.hd_income_band_sk
ORDER BY 
    ib.ib_income_band_sk;
