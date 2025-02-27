
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid,
        DATE_FORMAT(dd.d_date, '%Y-%m') AS sale_month
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023 
        AND cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_id, sale_month
), top_sales AS (
    SELECT 
        web_site_id, 
        ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS profit_rank
    FROM 
        sales_data
)
SELECT 
    sd.web_site_id,
    sd.total_net_profit,
    sd.total_orders,
    sd.avg_net_paid,
    ts.profit_rank
FROM 
    sales_data sd
JOIN 
    top_sales ts ON sd.web_site_id = ts.web_site_id
WHERE 
    ts.profit_rank <= 10
ORDER BY 
    sd.total_net_profit DESC;
