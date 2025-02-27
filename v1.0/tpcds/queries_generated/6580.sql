
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rnk
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year >= 2020 AND dd.d_year <= 2023
    GROUP BY 
        ws.web_site_id
),
TopWebSites AS (
    SELECT 
        web_site_id,
        total_net_profit,
        total_quantity,
        total_orders
    FROM 
        RankedSales
    WHERE 
        rnk <= 5
)
SELECT 
    tw.web_site_id,
    tw.total_net_profit,
    tw.total_quantity,
    tw.total_orders,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    TopWebSites tw
JOIN 
    web_site w ON tw.web_site_id = w.web_site_id
JOIN 
    customer c ON c.c_current_addr_sk = w.web_site_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
ORDER BY 
    tw.total_net_profit DESC, 
    tw.total_quantity DESC;
