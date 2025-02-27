
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
TopCustomers AS (
    SELECT 
        c.*,
        RANK() OVER (PARTITION BY c.cd_gender ORDER BY c.total_profit DESC) AS rank
    FROM 
        CustomerStats c
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.total_profit
FROM 
    TopCustomers tc
WHERE 
    tc.rank <= 5
ORDER BY 
    tc.cd_gender, tc.total_profit DESC;

SELECT 
    ws.ws_sold_date_sk,
    SUM(ws.ws_quantity) AS total_quantity_sold
FROM 
    web_sales ws
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    ws.ws_sold_date_sk
HAVING 
    SUM(ws.ws_quantity) > 100
ORDER BY 
    ws.ws_sold_date_sk;

SELECT 
    DISTINCT c.c_customer_id,
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    COALESCE(d.d_month_seq, 0) AS order_month,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit
FROM 
    customer c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, d.d_month_seq
HAVING 
    total_profit > 1000
ORDER BY 
    customer_name;
