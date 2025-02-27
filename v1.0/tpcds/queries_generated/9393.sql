
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND cd.cd_gender = 'F'
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        customer_id,
        total_net_profit,
        total_orders
    FROM 
        RankedSales
    WHERE 
        profit_rank <= 10
)
SELECT 
    tc.customer_id,
    tc.total_net_profit,
    tc.total_orders,
    AVG(CASE WHEN ws.ws_item_sk IS NOT NULL THEN 1 ELSE 0 END) AS avg_items_per_order,
    COUNT(DISTINCT ws.ws_item_sk) AS total_items_purchased
FROM 
    TopCustomers tc
LEFT JOIN 
    web_sales ws ON tc.customer_id = ws.ws_bill_customer_sk
GROUP BY 
    tc.customer_id, tc.total_net_profit, tc.total_orders
ORDER BY 
    tc.total_net_profit DESC;
