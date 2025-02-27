
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(DATEDIFF(DAY, d.d_date, GETDATE())) AS avg_days_since_last_order
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_profit,
        cs.total_quantity,
        CASE 
            WHEN cs.total_profit >= 1000 THEN 'Platinum'
            WHEN cs.total_profit >= 500 THEN 'Gold'
            ELSE 'Silver' 
        END AS customer_tier
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_orders > 0
)
SELECT 
    hvc.customer_tier,
    COUNT(hvc.c_customer_sk) AS customer_count,
    AVG(hvc.total_profit) AS avg_profit,
    AVG(hvc.total_quantity) AS avg_quantity,
    SUM(hvc.total_orders) AS total_orders_count
FROM 
    HighValueCustomers hvc
GROUP BY 
    hvc.customer_tier
ORDER BY 
    customer_count DESC;
