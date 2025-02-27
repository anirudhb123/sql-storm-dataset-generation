
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022 
        AND cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_id
),
ranked_sales AS (
    SELECT 
        web_site_id,
        total_profit,
        total_orders,
        avg_order_value,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM 
        sales_data
)
SELECT 
    w.web_site_name,
    rs.total_profit,
    rs.total_orders,
    rs.avg_order_value,
    rs.profit_rank
FROM 
    ranked_sales rs
JOIN 
    web_site w ON rs.web_site_id = w.web_site_id
WHERE 
    rs.profit_rank <= 10
ORDER BY 
    rs.total_profit DESC;
