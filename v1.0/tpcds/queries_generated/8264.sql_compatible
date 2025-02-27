
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
customer_demographics_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cs.cs_quantity) AS total_units_sold,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    INNER JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        cd.cd_gender
),
warehouse_performance AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ws.ws_order_number) AS orders_processed,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    s.web_site_id,
    s.total_sales,
    s.total_orders,
    s.avg_profit,
    s.unique_customers,
    cd.cd_gender,
    cd.customer_count,
    cd.total_units_sold,
    cd.total_net_profit,
    w.w_warehouse_id,
    w.orders_processed,
    w.total_revenue
FROM 
    sales_summary s
LEFT JOIN 
    customer_demographics_summary cd ON 1=1
LEFT JOIN 
    warehouse_performance w ON 1=1
ORDER BY 
    s.total_sales DESC, w.total_revenue DESC;
