
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        w.warehouse_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id, w.warehouse_id
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
summary AS (
    SELECT 
        si.web_site_id,
        si.warehouse_id,
        ci.cd_gender,
        SUM(si.total_sales) AS total_sales,
        SUM(si.order_count) AS total_orders,
        AVG(si.avg_net_profit) AS avg_profit,
        COUNT(DISTINCT ci.c_customer_id) AS customer_count
    FROM 
        sales_data si
    JOIN 
        customer_info ci ON si.web_site_id = ci.c_customer_id
    GROUP BY 
        si.web_site_id, si.warehouse_id, ci.cd_gender
)
SELECT 
    web_site_id, 
    warehouse_id, 
    cd_gender, 
    total_sales, 
    total_orders, 
    avg_profit,
    customer_count
FROM 
    summary
ORDER BY 
    total_sales DESC, customer_count DESC
LIMIT 100;
