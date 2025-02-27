
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk, 
        ws.web_site_id, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_moy IN (1, 2, 3) 
        AND ws.ws_net_profit > 0
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
), customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND cd.cd_purchase_estimate > 10000
)
SELECT 
    r.web_site_id,
    r.total_net_profit,
    r.total_orders,
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate
FROM 
    ranked_sales r
JOIN 
    customer_info ci ON r.web_site_sk = ci.c_customer_sk 
WHERE 
    r.profit_rank <= 10
ORDER BY 
    r.total_net_profit DESC, 
    ci.cd_purchase_estimate DESC;
