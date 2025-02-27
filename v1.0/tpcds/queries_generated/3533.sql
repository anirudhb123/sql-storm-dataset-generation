
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        cs.total_profit,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_profit > 0
)
SELECT 
    tc.first_name,
    tc.last_name,
    COALESCE(tc.total_orders, 0) AS total_orders,
    COALESCE(tc.total_profit, 0) AS total_profit,
    CASE 
        WHEN tc.profit_rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS customer_category,
    (SELECT COUNT(DISTINCT ws_item_sk) 
     FROM web_sales 
     WHERE ws_bill_customer_sk = tc.customer_sk AND ws_net_profit > 0) AS distinct_items_purchased
FROM 
    TopCustomers tc
LEFT JOIN 
    customer_demographics cd ON tc.customer_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F' AND 
    cd.cd_marital_status IS NOT NULL
ORDER BY 
    tc.total_profit DESC
LIMIT 100;

