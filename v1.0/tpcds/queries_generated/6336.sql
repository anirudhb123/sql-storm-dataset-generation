
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_paid) AS total_spent, 
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        c.customer_id, 
        cs.total_spent, 
        cs.total_orders 
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_spent > 1000
),
RecentOrders AS (
    SELECT 
        o.ws_ship_date_sk, 
        COUNT(o.ws_order_number) AS recent_order_count
    FROM 
        web_sales o
    JOIN 
        date_dim d ON o.ws_ship_date_sk = d.d_date_sk
    WHERE 
        d.d_date > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        o.ws_ship_date_sk
)
SELECT 
    hvc.customer_id, 
    hvc.total_spent, 
    hvc.total_orders, 
    ro.recent_order_count
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    RecentOrders ro ON hvc.customer_id = ro.ws_ship_customer_sk
ORDER BY 
    hvc.total_spent DESC, 
    hvc.total_orders DESC;
