
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
top_web_sites AS (
    SELECT 
        web_site_id,
        total_net_profit,
        total_orders
    FROM 
        ranked_sales
    WHERE 
        profit_rank <= 5
)
SELECT 
    tw.web_site_id,
    tw.total_net_profit,
    tw.total_orders,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers
FROM 
    top_web_sites tw
JOIN 
    customer c ON c.c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics cd WHERE cd.cd_gender = 'F')
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    tw.web_site_id, tw.total_net_profit, tw.total_orders
ORDER BY 
    tw.total_net_profit DESC;
