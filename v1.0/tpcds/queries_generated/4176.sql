
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_net_profit,
        cs.avg_net_paid,
        cs.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cs.total_net_profit > 1000 THEN 'High Value'
            WHEN cs.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
)
SELECT 
    hvc.customer_value,
    hvc.cd_gender,
    hvc.cd_marital_status,
    COUNT(*) AS customer_count,
    SUM(hvc.total_net_profit) AS total_net_profit,
    AVG(hvc.avg_net_paid) AS average_net_paid
FROM 
    HighValueCustomers hvc
GROUP BY 
    hvc.customer_value,
    hvc.cd_gender,
    hvc.cd_marital_status
HAVING 
    COUNT(*) > 1
ORDER BY 
    total_net_profit DESC;
