
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_bill_customer_sk
),
full_data AS (
    SELECT 
        cd.c_first_name, 
        cd.c_last_name, 
        cd.cd_gender, 
        sd.total_profit, 
        sd.order_count
    FROM 
        customer_data cd
    LEFT JOIN 
        sales_data sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
    WHERE 
        cd.gender_rank <= 10
)
SELECT 
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    COALESCE(f.total_profit, 0) AS total_profit,
    COALESCE(f.order_count, 0) AS order_count,
    CONCAT('Total Profit: $', COALESCE(f.total_profit, 0)::TEXT) AS profit_description
FROM 
    full_data f
ORDER BY 
    f.total_profit DESC
LIMIT 20;
