
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_ship_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                                 AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id AS customer_id,
        cs.total_net_profit,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    tc.customer_id,
    tc.total_net_profit,
    tc.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_credit_rating
FROM 
    TopCustomers tc 
JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_customer_id = tc.customer_id)
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_net_profit DESC;
