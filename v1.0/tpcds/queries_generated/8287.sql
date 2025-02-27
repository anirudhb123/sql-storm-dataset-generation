
WITH sales_summary AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales, 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders, 
        AVG(ws.ws_net_profit) AS avg_net_profit, 
        d.d_year AS sales_year
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        ws.web_site_id, d.d_year
),
customer_info AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        ci.ca_city AS customer_city
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ci ON c.c_current_addr_sk = ci.ca_address_sk
),
profit_analysis AS (
    SELECT 
        ss.web_site_id, 
        ss.total_sales, 
        ss.total_orders, 
        ss.avg_net_profit, 
        ci.customer_city
    FROM 
        sales_summary ss
    JOIN 
        customer_info ci ON ss.total_orders > 100
    ORDER BY 
        ss.total_sales DESC
)
SELECT 
    web_site_id, 
    total_sales, 
    total_orders, 
    avg_net_profit, 
    customer_city 
FROM 
    profit_analysis
WHERE 
    avg_net_profit > 50
LIMIT 10;
