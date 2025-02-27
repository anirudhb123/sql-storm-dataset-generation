
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_dep_count, 0) AS dependency_count,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
ranked_customers AS (
    SELECT 
        cs.*,
        RANK() OVER (PARTITION BY cs.income_band ORDER BY cs.total_spent DESC) AS spending_rank,
        COUNT(*) OVER (PARTITION BY cs.income_band) AS income_band_count
    FROM 
        customer_summary cs
),
top_spenders AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.total_spent,
        rc.income_band,
        rc.spending_rank,
        rc.income_band_count
    FROM 
        ranked_customers rc
    WHERE 
        rc.spending_rank <= 5
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.total_spent,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    t.income_band_count
FROM 
    top_spenders t
JOIN 
    income_band ib ON t.income_band = ib.ib_income_band_sk
ORDER BY 
    t.income_band, t.total_spent DESC;
