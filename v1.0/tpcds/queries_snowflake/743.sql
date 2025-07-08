
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.total_orders
    FROM 
        CustomerSales cs
    WHERE 
        cs.rank <= 10
),
ShippingModes AS (
    SELECT 
        sm.sm_ship_mode_id,
        sm.sm_type,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id, sm.sm_type
),
MonthlySales AS (
    SELECT 
        DATE_TRUNC('month', dd.d_date) AS sales_month,
        SUM(ws.ws_net_paid) AS monthly_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS monthly_orders
    FROM 
        date_dim dd
    JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        DATE_TRUNC('month', dd.d_date)
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    sm.sm_type AS shipping_method,
    ms.sales_month,
    ms.monthly_revenue
FROM 
    TopCustomers tc
JOIN 
    ShippingModes sm ON tc.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_net_paid = tc.total_spent LIMIT 1)
JOIN 
    MonthlySales ms ON 1=1
WHERE 
    ms.monthly_revenue > 100000
ORDER BY 
    tc.total_spent DESC, ms.sales_month DESC;
