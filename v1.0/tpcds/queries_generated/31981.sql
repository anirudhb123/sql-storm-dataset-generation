
WITH RECURSIVE sales_trends AS (
    SELECT 
        ws_sold_date_sk, 
        SUM(ws_net_profit) AS total_net_profit,
        1 AS level
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
    UNION ALL
    SELECT 
        ws_sold_date_sk, 
        total_net_profit * 1.1 AS total_net_profit,
        level + 1
    FROM 
        sales_trends
    WHERE 
        level < 5
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
)
SELECT 
    ca.c_customer_sk,
    ca.cd_gender,
    COALESCE(ca.total_orders, 0) AS total_orders,
    COALESCE(ca.total_spent, 0) AS total_spent,
    st.total_net_profit
FROM 
    customer_analysis AS ca
FULL OUTER JOIN 
    (SELECT SUM(total_net_profit) AS total_net_profit
     FROM sales_trends) AS st ON st.total_net_profit IS NOT NULL
WHERE 
    (ca.total_spent > 100 OR ca.total_orders > 10)
ORDER BY 
    total_spent DESC, total_orders DESC
LIMIT 100;
