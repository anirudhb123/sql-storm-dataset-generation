
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        hd.hd_buy_potential,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics AS hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M'
        AND hd.hd_buy_potential IN ('High', 'Medium')
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk, hd.hd_buy_potential
),
TopCustomers AS (
    SELECT 
        c.*, 
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerStats c
)
SELECT 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.cd_gender, 
    tc.total_orders, 
    tc.total_spent
FROM 
    TopCustomers tc
WHERE 
    tc.rank <= 10
ORDER BY 
    total_spent DESC;
