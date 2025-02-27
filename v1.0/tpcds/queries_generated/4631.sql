
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        total_net_profit > 1000
),
TopCustomers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        RANK() OVER (ORDER BY total_net_profit DESC) AS customer_rank
    FROM 
        CustomerSales
),
OrdersPerDay AS (
    SELECT 
        d.d_date,
        COUNT(ws.ws_order_number) AS total_orders_per_day,
        SUM(ws.ws_net_profit) AS daily_profit
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
    HAVING 
        daily_profit > 500
)
SELECT 
    tc.c_customer_sk, 
    tc.c_first_name, 
    tc.c_last_name, 
    opd.d_date,
    opd.total_orders_per_day,
    opd.daily_profit
FROM 
    TopCustomers tc
JOIN 
    OrdersPerDay opd ON tc.customer_rank <= 10
ORDER BY 
    opd.daily_profit DESC, tc.total_orders DESC
LIMIT 5;
