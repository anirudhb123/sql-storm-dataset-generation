
WITH ranked_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01'
        ) AND (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31'
        )
    GROUP BY 
        c.c_customer_id
)
SELECT 
    r.c_customer_id,
    r.total_net_profit,
    r.total_orders,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM 
    ranked_sales r
JOIN 
    customer_demographics cd ON r.c_customer_id = cd.cd_demo_sk
WHERE 
    r.profit_rank <= 10
ORDER BY 
    r.total_net_profit DESC;
