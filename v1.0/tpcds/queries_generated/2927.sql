
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_profit,
        cs.total_orders
    FROM 
        customer_stats cs
    WHERE 
        cs.total_profit > (SELECT AVG(total_profit) FROM customer_stats)
),
recent_activity AS (
    SELECT 
        cs.c_customer_sk,
        MAX(ws.ws_sold_date_sk) AS last_order_date
    FROM 
        high_value_customers cs
    JOIN 
        web_sales ws ON cs.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        cs.c_customer_sk
    HAVING 
        MAX(ws.ws_sold_date_sk) > (SELECT MAX(d.d_date) - INTERVAL '30' DAY FROM date_dim d)
)
SELECT 
    h.c_first_name,
    h.c_last_name,
    h.total_profit,
    h.total_orders,
    COALESCE(r.last_order_date, 'No recent order') AS last_order_date,
    CASE 
        WHEN r.last_order_date IS NULL THEN 'Inactive' 
        ELSE 'Active' 
    END AS customer_status
FROM 
    high_value_customers h
LEFT JOIN 
    recent_activity r ON h.c_customer_sk = r.c_customer_sk
JOIN 
    date_dim d ON d.d_date_sk = (SELECT d.d_date_sk FROM date_dim WHERE d.d_date = CURRENT_DATE)
WHERE 
    d.d_current_month = 'Y'
ORDER BY 
    h.total_profit DESC, h.total_orders DESC;
