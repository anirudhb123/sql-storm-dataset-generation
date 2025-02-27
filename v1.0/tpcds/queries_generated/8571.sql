
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND dd.d_year = 2023 
        AND ws.net_profit > 0
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
        profit_rank <= 5
)
SELECT 
    tw.web_site_id,
    tw.total_net_profit,
    tw.total_orders,
    (tw.total_net_profit / NULLIF(tw.total_orders, 0)) AS average_profit_per_order
FROM 
    TopWebsites tw
ORDER BY 
    tw.total_net_profit DESC;
