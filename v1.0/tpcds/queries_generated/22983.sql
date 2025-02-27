
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 
            (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND 
            (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cs.total_web_profit,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_web_profit DESC) AS profit_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
FrequentShippers AS (
    SELECT 
        ws.ws_ship_mode_sk,
        sm.sm_type,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws.ws_ship_mode_sk, sm.sm_type
)
SELECT 
    tc.full_name,
    tc.total_web_profit,
    tc.order_count,
    COALESCE(f.total_quantity, 0) AS total_quantity,
    COALESCE(f.avg_net_paid, 0) AS avg_net_paid,
    CASE 
        WHEN tc.profit_rank <= 10 THEN 'Top 10 Customer'
        ELSE 'Other Customer'
    END AS customer_category
FROM 
    TopCustomers tc
LEFT JOIN 
    FrequentShippers f ON tc.order_count = (SELECT MAX(order_count) FROM TopCustomers) 
WHERE 
    tc.total_web_profit IS NOT NULL
ORDER BY 
    tc.total_web_profit DESC
FETCH FIRST 20 ROWS ONLY;
