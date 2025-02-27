
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        SUM(ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
    FROM 
        store
    LEFT JOIN 
        store_sales ON store.s_store_sk = store_sales.ss_store_sk
    GROUP BY 
        s_store_sk, s_store_name
    HAVING 
        SUM(ss_net_profit) IS NOT NULL
), 
daily_sales AS (
    SELECT 
        d.d_date,
        SUM(ws_net_profit) AS daily_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
)

SELECT 
    ch.s_store_name,
    d.daily_profit,
    cs.cd_gender,
    cs.total_spent as customer_spending,
    cs.total_orders as customer_orders,
    ROUND((SELECT AVG(total_spent) FROM customer_stats), 2) AS avg_customer_spending,
    ARRAY_AGG(DISTINCT cs.c_customer_sk) FILTER (WHERE cs.total_spent > 500) AS high_value_customers
FROM 
    sales_hierarchy ch
JOIN 
    daily_sales d ON d.daily_profit > 1000
JOIN 
    customer_stats cs ON cs.total_orders > 5
WHERE 
    ch.total_profit > 10000
GROUP BY 
    ch.s_store_name, d.daily_profit, cs.cd_gender;
