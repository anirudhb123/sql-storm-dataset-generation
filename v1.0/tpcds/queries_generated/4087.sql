
WITH RecentSales AS (
    SELECT 
        ws.web_site_id,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year < 1980
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ss.net_paid) > 1000
),
TopShippingModes AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(ws.order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
    ORDER BY 
        order_count DESC
    LIMIT 5
)
SELECT 
    r.web_site_id,
    r.total_orders,
    r.total_net_profit,
    h.c_customer_id AS high_value_customer_id,
    h.total_spent AS high_value_total_spent,
    t.sm_ship_mode_id,
    t.order_count
FROM 
    RecentSales r
LEFT JOIN 
    HighValueCustomers h ON r.total_net_profit > 5000
JOIN 
    TopShippingModes t ON r.total_orders > 10
WHERE 
    r.total_net_profit IS NOT NULL
ORDER BY 
    r.total_net_profit DESC, r.total_orders ASC;
