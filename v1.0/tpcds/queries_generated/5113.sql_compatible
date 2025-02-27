
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_name,
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        w.w_warehouse_name, d.d_year
), customer_info AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
), demographics_summary AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status, 
        COUNT(DISTINCT ci.c_customer_id) AS customer_count,
        SUM(ci.total_spent) AS total_revenue
    FROM 
        customer_info ci
    JOIN 
        customer_demographics cd ON ci.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ss.w_warehouse_name,
    ss.d_year,
    ss.total_quantity,
    ss.total_sales,
    ds.cd_gender,
    ds.cd_marital_status,
    ds.customer_count,
    ds.total_revenue
FROM 
    sales_summary ss
JOIN 
    demographics_summary ds ON ss.total_sales > 10000
ORDER BY 
    ss.d_year DESC, ss.total_sales DESC;
