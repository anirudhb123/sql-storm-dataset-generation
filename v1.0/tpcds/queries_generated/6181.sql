
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_moy IN (11, 12) 
    GROUP BY 
        ws.web_site_id
),
TopWebsites AS (
    SELECT 
        web_site_id, 
        total_net_profit, 
        total_orders 
    FROM 
        RankedSales 
    WHERE 
        rank <= 5
)
SELECT 
    w.web_site_id, 
    w.web_name, 
    t.total_net_profit, 
    t.total_orders, 
    (SELECT COUNT(DISTINCT c.c_customer_id) FROM customer c JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk WHERE ws.ws_web_site_sk = w.web_site_sk) AS unique_customers
FROM 
    web_site w
JOIN 
    TopWebsites t ON w.web_site_id = t.web_site_id
ORDER BY 
    t.total_net_profit DESC;
