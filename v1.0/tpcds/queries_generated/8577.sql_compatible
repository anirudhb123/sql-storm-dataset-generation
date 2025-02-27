
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid) AS avg_order_value,
        MIN(ws.ws_sold_date_sk) AS first_order_date,
        MAX(ws.ws_sold_date_sk) AS last_order_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
OrderCounts AS (
    SELECT 
        total_orders,
        NTILE(4) OVER (ORDER BY total_orders) AS order_quartile
    FROM 
        CustomerSales
),
Profits AS (
    SELECT 
        total_profit,
        NTILE(4) OVER (ORDER BY total_profit) AS profit_quartile
    FROM 
        CustomerSales
),
FinalResults AS (
    SELECT 
        cs.c_customer_sk,
        oc.order_quartile,
        p.profit_quartile,
        cs.total_orders,
        cs.total_profit,
        cs.avg_order_value,
        cs.first_order_date,
        cs.last_order_date
    FROM 
        CustomerSales cs
    JOIN 
        OrderCounts oc ON cs.total_orders = oc.total_orders
    JOIN 
        Profits p ON cs.total_profit = p.total_profit
)
SELECT 
    f.c_customer_sk,
    f.order_quartile,
    f.profit_quartile,
    f.total_orders,
    f.total_profit,
    f.avg_order_value,
    DATEDIFF(f.last_order_date, f.first_order_date) AS order_duration_days
FROM 
    FinalResults f
WHERE 
    f.total_orders > 5 AND f.total_profit > 1000
ORDER BY 
    f.total_profit DESC, 
    f.total_orders ASC;
