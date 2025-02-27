
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        w.w_warehouse_id, d.d_year
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity_bought,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
demographics_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(c.c_customer_sk) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ss.w_warehouse_id,
    ss.d_year,
    ss.total_quantity_sold,
    ss.total_sales,
    ss.avg_net_profit,
    cs.total_quantity_bought,
    cs.total_spent,
    ds.total_customers,
    ds.avg_purchase_estimate
FROM 
    sales_summary ss
FULL OUTER JOIN 
    customer_summary cs ON ss.w_warehouse_id = (SELECT w.w_warehouse_id FROM warehouse w LIMIT 1)
FULL OUTER JOIN 
    demographics_summary ds ON ds.total_customers > 100
ORDER BY 
    ss.d_year, ss.total_sales DESC;
