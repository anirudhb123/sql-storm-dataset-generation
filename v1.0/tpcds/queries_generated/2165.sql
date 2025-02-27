
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
income_distribution AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(cs.c_customer_sk) AS customer_count
    FROM 
        income_band ib
    LEFT JOIN 
        customer_summary cs ON ib.ib_income_band_sk = cs.cd_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
top_customers AS (
    SELECT 
        customer_summary.c_customer_sk,
        customer_summary.c_first_name,
        customer_summary.c_last_name,
        customer_summary.total_spent,
        RANK() OVER (ORDER BY customer_summary.total_spent DESC) AS rank
    FROM 
        customer_summary
)
SELECT 
    ic.ib_lower_bound,
    ic.ib_upper_bound,
    COALESCE(tc.total_spent, 0) AS top_customer_spent,
    ic.customer_count
FROM 
    income_distribution ic
LEFT JOIN 
    (SELECT 
         c.c_first_name,
         c.c_last_name,
         cs.total_spent
     FROM 
         customer_summary cs
     JOIN 
         top_customers tc ON cs.c_customer_sk = tc.c_customer_sk
     WHERE 
         tc.rank <= 10) AS tc ON ic.ib_income_band_sk = tc.cd_income_band_sk
ORDER BY 
    ic.ib_income_band_sk;
