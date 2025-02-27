
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_spent_per_order
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), 
warehouse_summary AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
),
sales_summary AS (
    SELECT 
        d.d_year,
        sm.sm_type,
        SUM(ws.ws_net_sales) AS total_net_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(ws.ws_order_number) AS total_transactions
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        d.d_year, sm.sm_type
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    ws.total_orders AS customer_orders,
    ws.total_spent AS customer_spent,
    wsavg_spent_per_order AS customer_avg_spent,
    wh.w_warehouse_name,
    wh.total_orders AS warehouse_orders,
    wh.total_revenue AS warehouse_revenue,
    ss.d_year,
    ss.sm_type,
    ss.total_net_sales,
    ss.total_discount,
    ss.total_transactions
FROM 
    customer_summary cs
JOIN 
    warehouse_summary wh ON cs.c_customer_sk % 10 = wh.w_warehouse_sk % 10 -- arbitrary joining logic for demo
JOIN 
    sales_summary ss ON cs.total_orders = ss.total_transactions
WHERE 
    cs.total_spent > 1000
ORDER BY 
    cs.last_name, cs.first_name;
