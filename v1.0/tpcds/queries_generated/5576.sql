
WITH SalesData AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers,
        AVG(ws.ws_net_paid_inc_tax) AS average_order_value,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_sales
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
SalesRank AS (
    SELECT 
        web_site_id, 
        total_net_profit,
        total_orders,
        unique_customers,
        average_order_value,
        rank_sales
    FROM 
        SalesData
)
SELECT 
    w.web_site_name, 
    sr.total_net_profit,
    sr.total_orders,
    sr.unique_customers,
    sr.average_order_value
FROM 
    SalesRank AS sr
JOIN 
    web_site AS w ON sr.web_site_id = w.web_site_id
WHERE 
    sr.rank_sales <= 10
ORDER BY 
    sr.total_net_profit DESC;
