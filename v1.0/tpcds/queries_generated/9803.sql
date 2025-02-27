
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_quantity) AS avg_quantity_per_order,
        d.d_year AS sale_year
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.web_site_id, d.d_year
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ss.web_site_id,
    ss.sale_year,
    ss.total_net_profit,
    ss.total_orders,
    ss.avg_quantity_per_order,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_net_profit AS customer_total_net_profit
FROM 
    sales_summary ss
JOIN 
    customer_summary cs ON ss.total_net_profit = cs.total_net_profit
WHERE 
    ss.total_net_profit > 10000
ORDER BY 
    ss.sale_year DESC, ss.total_net_profit DESC
LIMIT 100;
