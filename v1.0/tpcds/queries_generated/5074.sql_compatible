
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_net_paid) AS total_paid
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
TopCustomers AS (
    SELECT 
        cs.*, 
        RANK() OVER (PARTITION BY cs.cd_income_band_sk ORDER BY cs.total_profit DESC) AS income_rank
    FROM 
        CustomerStats cs
)
SELECT 
    t.*, 
    ib.ib_lower_bound, 
    ib.ib_upper_bound
FROM 
    TopCustomers t
JOIN 
    income_band ib ON t.cd_income_band_sk = ib.ib_income_band_sk
WHERE 
    t.income_rank <= 5
ORDER BY 
    t.cd_income_band_sk, t.total_profit DESC;
