
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
IncomeBands AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(cs.c_customer_id) AS customer_count,
        SUM(cs.total_orders) AS total_orders,
        SUM(cs.total_spent) AS total_spent,
        AVG(cs.avg_spent) AS avg_spent
    FROM 
        CustomerStats cs
    JOIN 
        household_demographics hd ON cs.cd_income_band_sk = hd.hd_income_band_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ib.customer_count,
    ib.total_orders,
    ib.total_spent,
    ib.avg_spent,
    RANK() OVER (ORDER BY ib.total_spent DESC) AS rank_by_spending
FROM 
    IncomeBands ib
ORDER BY 
    ib.total_spent DESC;
