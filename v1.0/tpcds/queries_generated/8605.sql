
WITH ranked_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        c.c_customer_id, c.c_customer_sk
),
top_customers AS (
    SELECT 
        customer_id,
        total_profit,
        order_count
    FROM 
        ranked_sales
    WHERE 
        rank = 1
)
SELECT 
    tc.customer_id,
    tc.total_profit,
    tc.order_count,
    COALESCE(CAST(SUM(sr.sr_return_amt) AS DECIMAL(10, 2)), 0) AS total_returns,
    CASE 
        WHEN tc.order_count > 0 THEN (tc.total_profit - COALESCE(SUM(sr.sr_return_amt), 0)) / tc.order_count 
        ELSE 0 END AS avg_profit_per_order
FROM 
    top_customers tc
LEFT JOIN 
    store_returns sr ON tc.customer_id = sr.sr_customer_sk
GROUP BY 
    tc.customer_id, tc.total_profit, tc.order_count
ORDER BY 
    tc.total_profit DESC
LIMIT 10;
