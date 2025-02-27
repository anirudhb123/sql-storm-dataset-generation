
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        COALESCE(hd.hd_dep_count, 0) AS dep_count,
        COALESCE(hd.hd_vehicle_count, 0) AS vehicle_count,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_spent
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
        ROW_NUMBER() OVER (PARTITION BY cs.hd_income_band_sk ORDER BY cs.total_spent DESC) AS rank
    FROM 
        customer_summary cs
)
SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    rc.dep_count,
    rc.vehicle_count,
    rc.total_quantity,
    rc.total_spent
FROM 
    ranked_customers rc
JOIN 
    income_band ib ON rc.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.hd_income_band_sk, rc.total_spent DESC;
