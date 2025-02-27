
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
TopProfitCustomers AS (
    SELECT 
        rc.c_customer_id,
        rc.total_profit,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status
    FROM 
        RankedCustomers rc
    WHERE 
        rc.profit_rank <= 5
)
SELECT 
    tpc.c_customer_id,
    tpc.total_profit,
    tpc.cd_gender,
    tpc.cd_marital_status,
    tpc.cd_education_status,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_quantity) AS total_items_sold,
    SUM(ws.ws_net_paid_inc_tax) AS total_amount_paid
FROM  
    TopProfitCustomers tpc
JOIN 
    web_sales ws ON tpc.c_customer_id = ws.ws_bill_customer_sk
GROUP BY 
    tpc.c_customer_id, tpc.total_profit, tpc.cd_gender, tpc.cd_marital_status, tpc.cd_education_status
ORDER BY 
    total_profit DESC;
