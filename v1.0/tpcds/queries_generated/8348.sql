
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        hd.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk, hd.hd_income_band_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        RankedCustomers rc
    JOIN 
        customer c ON rc.c_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        rc.rnk <= 10
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_profit,
    COUNT(ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
FROM 
    TopCustomers tc
JOIN 
    web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.cd_gender, tc.cd_marital_status, tc.total_profit
ORDER BY 
    tc.total_profit DESC;
