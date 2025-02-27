
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        dd.d_year = 2023 AND 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' AND 
        cd.cd_education_status IN ('Bachelors', 'Masters', 'PhD')
    GROUP BY 
        ws.web_site_id
),
shipping_summary AS (
    SELECT 
        sm.sm_ship_mode_id,
        SUM(ws.ws_ext_ship_cost) AS total_shipping_cost,
        SUM(ws.ws_quantity) AS total_items_shipped
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
)
SELECT 
    ss.web_site_id,
    ss.total_sales,
    ss.total_orders,
    ss.unique_customers,
    ss.avg_order_value,
    sh.sm_ship_mode_id,
    sh.total_shipping_cost,
    sh.total_items_shipped
FROM 
    sales_summary ss
JOIN 
    shipping_summary sh ON ss.total_orders > 100
ORDER BY 
    ss.total_sales DESC
LIMIT 10;
