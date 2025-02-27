
WITH SalesData AS (
    SELECT 
        ws.bill_customer_sk,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        AVG(ws.net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws.bill_customer_sk, cd.gender, cd.marital_status, cd.education_status
),
TopCustomers AS (
    SELECT 
        bill_customer_sk,
        total_net_profit,
        total_orders,
        avg_order_value,
        RANK() OVER (ORDER BY total_net_profit DESC) AS rank
    FROM 
        SalesData
),
CustomerRanks AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        tc.total_net_profit,
        tc.total_orders,
        tc.avg_order_value,
        tc.rank
    FROM 
        TopCustomers tc
    JOIN 
        customer c ON tc.bill_customer_sk = c.c_customer_sk
)
SELECT 
    cr.c_customer_id,
    cr.c_first_name,
    cr.c_last_name,
    cr.total_net_profit,
    cr.total_orders,
    cr.avg_order_value
FROM 
    CustomerRanks cr
WHERE 
    cr.rank <= 10
ORDER BY 
    cr.total_net_profit DESC;
