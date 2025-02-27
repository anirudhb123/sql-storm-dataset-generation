
WITH CustomerWebSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        cws.c_customer_id,
        cws.total_net_profit,
        cws.total_orders,
        (cws.total_net_profit / cws.total_orders) AS avg_profit_per_order
    FROM 
        CustomerWebSales cws
    WHERE 
        cws.total_net_profit > (SELECT AVG(total_net_profit) FROM CustomerWebSales)
)
SELECT 
    cwc.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    cwc.total_net_profit,
    cwc.avg_profit_per_order,
    d.d_year,
    d.d_month_seq
FROM 
    HighValueCustomers cwc
JOIN 
    customer c ON c.c_customer_id = cwc.c_customer_id
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws.ws_ship_date_sk) FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk)
ORDER BY 
    cwc.total_net_profit DESC
LIMIT 10;
