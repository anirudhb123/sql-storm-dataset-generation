
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        customer_id, 
        total_profit
    FROM 
        RankedSales
    WHERE 
        rank <= 10
)
SELECT 
    tc.customer_id,
    tc.total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    AVG(ws.ws_net_paid) AS avg_order_value
FROM 
    TopCustomers tc
JOIN 
    web_sales ws ON tc.customer_id = ws.ws_bill_customer_sk
GROUP BY 
    tc.customer_id, tc.total_profit
ORDER BY 
    tc.total_profit DESC;
