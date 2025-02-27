
WITH RECURSIVE daily_sales AS (
    SELECT 
        d.d_date, 
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date
    UNION ALL
    SELECT 
        d.d_date, 
        ds.total_net_profit + COALESCE(SUM(ws.ws_net_profit), 0)
    FROM 
        daily_sales ds
    JOIN date_dim d ON d.d_date > ds.d_date
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk 
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date, ds.total_net_profit
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS customer_net_profit
    FROM 
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws.ws_net_profit) > (
            SELECT 
                AVG(total_net_profit) 
            FROM 
                (SELECT 
                    SUM(ws2.ws_net_profit) AS total_net_profit 
                FROM 
                    web_sales ws2 
                GROUP BY 
                    ws2.ws_ship_customer_sk) AS avg_profit
        )
)
SELECT 
    d.d_date,
    ds.total_net_profit,
    tc.c_customer_id,
    tc.customer_net_profit
FROM 
    daily_sales ds
JOIN date_dim d ON d.d_date = ds.d_date
LEFT JOIN top_customers tc ON tc.customer_net_profit = (
    SELECT 
        MAX(customer_net_profit) 
    FROM 
        top_customers
)
WHERE 
    d.d_dow IN (1, 2, 3) -- Monday, Tuesday, Wednesday
ORDER BY 
    d.d_date;
