
WITH annual_sales AS (
    SELECT 
        w.w_warehouse_id,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        w.w_warehouse_id, d.d_year
),
demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
sales_summary AS (
    SELECT 
        a.w_warehouse_id,
        a.d_year,
        a.total_sales,
        a.total_net_paid,
        a.avg_sales_price,
        a.total_orders,
        d.cd_gender,
        d.cd_marital_status,
        d.customer_count
    FROM 
        annual_sales a
    JOIN 
        demographics d ON a.w_warehouse_id = (SELECT w.w_warehouse_id FROM warehouse w ORDER BY RANDOM() LIMIT 1)
)
SELECT 
    w.w_warehouse_name,
    ss.d_year,
    ss.total_sales,
    ss.total_net_paid,
    ss.avg_sales_price,
    ss.total_orders,
    ss.cd_gender,
    ss.cd_marital_status,
    ss.customer_count
FROM 
    sales_summary ss
JOIN 
    warehouse w ON ss.w_warehouse_id = w.w_warehouse_id
WHERE 
    ss.total_sales IS NOT NULL
ORDER BY 
    ss.d_year, ss.total_sales DESC;
