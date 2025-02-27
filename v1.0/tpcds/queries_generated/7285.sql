
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_name,
        d.d_year,
        SUM(ws.ws_net_sales) AS total_net_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        w.w_warehouse_name, d.d_year
), 
customer_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_id) AS total_customers,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd.cd_credit_rating) AS avg_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ss.w_warehouse_name,
    ss.d_year,
    ss.total_net_sales,
    ss.total_orders,
    ss.avg_order_value,
    cs.cd_gender,
    cs.total_customers,
    cs.total_purchase_estimate,
    cs.avg_credit_rating
FROM 
    sales_summary ss
JOIN 
    customer_summary cs ON ss.total_orders > 1000
ORDER BY 
    ss.total_net_sales DESC, cs.total_customers DESC;
