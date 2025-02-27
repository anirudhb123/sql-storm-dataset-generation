
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id
), customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
), top_products AS (
    SELECT 
        i.i_item_id,
        SUM(cs.cs_quantity) AS total_sold,
        SUM(cs.cs_sales_price) AS total_revenue
    FROM 
        catalog_sales cs
    JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
    ORDER BY 
        total_revenue DESC
    LIMIT 10
)
SELECT 
    ss.web_site_id,
    ss.total_sales,
    ss.total_orders,
    ss.avg_profit,
    ss.unique_customers,
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_orders AS customer_orders,
    cs.total_spent,
    tp.i_item_id,
    tp.total_sold,
    tp.total_revenue
FROM 
    sales_summary ss
JOIN 
    customer_summary cs ON ss.unique_customers > 1000
JOIN 
    top_products tp ON tp.total_sold > 500
ORDER BY 
    ss.total_sales DESC, cs.total_spent DESC;
