
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 2000
    GROUP BY 
        c.c_customer_id
),
Demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cs.total_profit) AS avg_profit,
        SUM(cs.total_orders) AS total_orders
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    d.cd_gender, 
    d.cd_marital_status, 
    d.avg_profit, 
    d.total_orders, 
    COUNT(d.cd_gender) OVER() AS total_entries
FROM 
    Demographics d
ORDER BY 
    d.avg_profit DESC, 
    d.total_orders DESC
LIMIT 10;
