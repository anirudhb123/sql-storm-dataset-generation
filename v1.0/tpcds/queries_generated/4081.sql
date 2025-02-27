
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
        AND c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cs.total_net_profit,
        cs.total_orders,
        cs.avg_order_value,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.full_name,
    tc.total_net_profit,
    tc.total_orders,
    tc.avg_order_value,
    COALESCE(sm.sm_carrier, 'N/A') AS preferred_shipper,
    CASE 
        WHEN tc.total_orders > 10 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_category
FROM 
    TopCustomers tc
LEFT JOIN 
    ship_mode sm ON tc.total_orders = (SELECT COUNT(DISTINCT ws.ws_order_number) FROM web_sales ws WHERE ws.ws_bill_customer_sk = tc.c_customer_sk)
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_net_profit DESC
LIMIT 10;
