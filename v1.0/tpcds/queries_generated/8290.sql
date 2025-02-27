
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_profit,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_orders > 5
),
HighProfitDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(tc.customer_id) AS customer_count,
        AVG(tc.total_profit) AS avg_profit
    FROM 
        TopCustomers tc
    JOIN 
        customer_demographics cd ON tc.customer_id = cd.cd_demo_sk
    WHERE 
        tc.profit_rank <= 100
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    hpd.cd_gender, 
    hpd.cd_marital_status, 
    hpd.customer_count, 
    hpd.avg_profit,
    ROW_NUMBER() OVER (ORDER BY hpd.avg_profit DESC) AS demo_rank
FROM 
    HighProfitDemographics hpd
ORDER BY 
    hpd.avg_profit DESC;
