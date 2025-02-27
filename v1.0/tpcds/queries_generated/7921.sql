
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
), Demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(cs.c_customer_id) AS customer_count,
        AVG(cs.total_net_profit) AS avg_net_profit,
        AVG(cs.total_orders) AS avg_orders
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
), AggregateStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(customer_count) AS total_customers,
        SUM(avg_net_profit) AS total_avg_net_profit,
        SUM(avg_orders) AS total_avg_orders
    FROM 
        Demographics
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    total_customers,
    total_avg_net_profit,
    total_avg_orders
FROM 
    AggregateStats
WHERE 
    total_avg_net_profit > 1000 
ORDER BY 
    total_avg_net_profit DESC;
