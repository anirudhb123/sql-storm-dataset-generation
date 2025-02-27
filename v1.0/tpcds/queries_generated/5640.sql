
WITH RankedSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        c.c_customer_id
),

HighValueCustomers AS (
    SELECT 
        customer_id,
        total_profit,
        order_count
    FROM 
        RankedSales
    WHERE 
        profit_rank <= 100
)

SELECT 
    hvc.customer_id,
    hvc.total_profit,
    hvc.order_count,
    COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased,
    AVG(ws.ws_net_paid) AS avg_order_value,
    SUM(ws.ws_ext_ship_cost) AS total_shipping_cost
FROM 
    HighValueCustomers hvc
JOIN 
    web_sales ws ON hvc.customer_id = ws.ws_bill_customer_sk
GROUP BY 
    hvc.customer_id, hvc.total_profit, hvc.order_count
ORDER BY 
    hvc.total_profit DESC;
