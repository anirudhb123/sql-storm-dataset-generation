
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ROUND(SUM(ws.ws_net_paid_inc_tax), 2) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
average_spending AS (
    SELECT
        cd.cd_income_band_sk,
        AVG(total_spent) AS avg_spent
    FROM 
        customer_info ci
    JOIN 
        household_demographics hd ON ci.cd_income_band_sk = hd.hd_income_band_sk
    JOIN 
        customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_income_band_sk
),
top_spenders AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.total_spent,
        ROW_NUMBER() OVER (ORDER BY ci.total_spent DESC) AS rnk
    FROM 
        customer_info ci
)
SELECT 
    ts.c_customer_sk,
    ts.c_first_name,
    ts.c_last_name,
    ts.total_spent,
    ab.avg_spent,
    CASE 
        WHEN ts.total_spent > ab.avg_spent THEN 'Above Average'
        WHEN ts.total_spent = ab.avg_spent THEN 'Average'
        ELSE 'Below Average' 
    END AS spending_category
FROM 
    top_spenders ts
LEFT JOIN 
    average_spending ab ON ts.cd_income_band_sk = ab.cd_income_band_sk
WHERE 
    ts.rnk <= 10
ORDER BY 
    ts.total_spent DESC;
