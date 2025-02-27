
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_income_band_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_income_band_sk
),
top_customers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_income_band_sk ORDER BY total_profit DESC) AS income_band_rank
    FROM 
        ranked_customers
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    tc.total_orders,
    tc.total_profit
FROM 
    top_customers tc
JOIN 
    income_band ib ON tc.cd_income_band_sk = ib.ib_income_band_sk
WHERE 
    tc.income_band_rank <= 10
ORDER BY 
    tc.cd_income_band_sk, tc.total_profit DESC;
