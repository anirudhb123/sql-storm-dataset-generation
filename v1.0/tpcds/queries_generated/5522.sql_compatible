
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_sales_price - ws.ws_net_profit) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        d.d_year AS sales_year
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        ws.web_site_id, d.d_year
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ss.web_site_id,
    ss.total_sales,
    ss.total_discount,
    ss.total_orders,
    cs.cd_gender,
    cs.cd_marital_status,
    AVG(cs.order_count) AS avg_orders_per_customer
FROM 
    sales_summary ss
JOIN 
    customer_summary cs ON ss.total_orders > 0
GROUP BY 
    ss.web_site_id, ss.total_sales, ss.total_discount, cs.cd_gender, cs.cd_marital_status
ORDER BY 
    ss.total_sales DESC
LIMIT 10;
