
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        dd.d_year = 2023 AND 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        ws.web_site_sk
)
SELECT 
    ws.web_site_id, 
    ws.web_name, 
    rs.total_profit, 
    rs.total_orders 
FROM 
    RankedSales rs
JOIN 
    web_site ws ON rs.web_site_sk = ws.web_site_sk
WHERE 
    rs.rank <= 10
ORDER BY 
    rs.total_profit DESC;
