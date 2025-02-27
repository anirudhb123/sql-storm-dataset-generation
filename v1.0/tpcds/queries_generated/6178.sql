
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    JOIN 
        customer_demographics cd ON ws.bill_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
        AND cd.cd_education_status IN ('Bachelor’s', 'Master’s')
    GROUP BY 
        ws.bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        rs.total_orders,
        rs.total_profit
    FROM 
        RankedSales rs
    JOIN 
        customer c ON rs.bill_customer_sk = c.c_customer_sk
    WHERE 
        rs.rank_profit <= 10
)
SELECT 
    tc.c_customer_id,
    tc.total_orders,
    tc.total_profit,
    (SELECT COUNT(DISTINCT ws.ws_order_number) 
     FROM web_sales ws 
     WHERE ws.bill_customer_sk = tc.c_customer_id) AS total_unique_orders,
    (SELECT SUM(ws.ws_net_paid) 
     FROM web_sales ws 
     WHERE ws.bill_customer_sk = tc.c_customer_id) AS total_amount_spent
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_profit DESC;
