
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_net_paid) AS avg_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        cd.cd_gender = 'M' AND 
        cd.cd_marital_status = 'S'
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c_customer_id,
        total_quantity_sold,
        total_sales,
        avg_sales,
        total_orders,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    tc.c_customer_id,
    tc.total_quantity_sold,
    tc.total_sales,
    tc.avg_sales,
    tc.total_orders,
    w.w_warehouse_name,
    sm.sm_carrier
FROM 
    top_customers tc
JOIN 
    web_sales ws ON tc.c_customer_id = ws.ws_bill_customer_sk
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
