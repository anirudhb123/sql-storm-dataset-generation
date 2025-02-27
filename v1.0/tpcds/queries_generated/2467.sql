
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ws.ws_net_profit) OVER (PARTITION BY cd.cd_gender) AS median_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_orders,
        cs.total_profit,
        ROW_NUMBER() OVER (ORDER BY cs.total_profit DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_stats cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        cs.total_orders > 5
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_orders,
    tc.total_profit,
    CASE 
        WHEN tc.total_profit > 1000 THEN 'High Value Customer'
        WHEN tc.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category,
    COALESCE((
        SELECT 
            COUNT(*) 
        FROM 
            store_returns sr 
        WHERE 
            sr.sr_customer_sk = tc.c_customer_sk
    ), 0) AS returns_count,
    DENSE_RANK() OVER (ORDER BY tc.total_profit DESC) AS customer_rank
FROM 
    top_customers tc
WHERE 
    tc.rn <= 10
ORDER BY 
    tc.total_profit DESC;

