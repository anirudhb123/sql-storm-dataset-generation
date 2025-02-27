
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        d.d_year,
        c.c_birth_country,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        ws.web_site_id, d.d_year, c.c_birth_country, cd.cd_gender, cd.cd_marital_status
),
ranked_sales AS (
    SELECT 
        web_site_id,
        total_net_profit,
        total_orders,
        avg_order_value,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS rank
    FROM 
        sales_data
)
SELECT 
    r.web_site_id,
    r.total_net_profit,
    r.total_orders,
    r.avg_order_value,
    r.rank,
    r.d_year
FROM 
    ranked_sales r
WHERE 
    r.rank <= 10
ORDER BY 
    r.d_year, r.rank;
