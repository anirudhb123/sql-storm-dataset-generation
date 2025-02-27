
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER(PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND dd.d_year = 2022 
        AND ws.ws_net_profit > 100
    GROUP BY 
        ws.web_site_id
)

SELECT 
    r.web_site_id, 
    r.total_net_profit, 
    r.total_orders,
    d.d_month_seq,
    d.d_year
FROM 
    ranked_sales r
JOIN 
    date_dim d ON r.web_site_id = d.d_date_sk
WHERE 
    r.profit_rank <= 10
ORDER BY 
    r.total_net_profit DESC;
