
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
FilteredCustomers AS (
    SELECT 
        cs.c_customer_id, 
        cs.total_spent,
        cs.total_orders
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent > (
            SELECT AVG(total_spent) FROM CustomerSales
        ) AND cs.total_orders > 5
),
RecentOrders AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_net_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 
        (SELECT MAX(d.d_date) FROM date_dim d) - INTERVAL '30 days' AND 
        (SELECT MAX(d.d_date) FROM date_dim d)
)
SELECT 
    fc.c_customer_id,
    fc.total_spent,
    fc.total_orders,
    COUNT(ro.ws_order_number) AS recent_order_count,
    SUM(ro.ws_net_profit) AS total_recent_profit
FROM 
    FilteredCustomers fc
LEFT JOIN 
    RecentOrders ro ON fc.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = ro.ws_bill_customer_sk)
GROUP BY 
    fc.c_customer_id, fc.total_spent, fc.total_orders
ORDER BY 
    total_recent_profit DESC
LIMIT 100;
