
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_name,
        s.s_store_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        AVG(ws.ws_net_paid) AS average_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_addr_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        w.w_warehouse_name, s.s_store_name
),
customer_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ss.warehouse_name,
    ss.store_name,
    ss.total_quantity_sold,
    ss.total_sales_amount,
    ss.average_net_paid,
    cs.total_customers,
    cs.total_purchase_estimate
FROM 
    sales_summary ss
JOIN 
    customer_summary cs ON cs.total_customers > 1000
ORDER BY 
    ss.total_sales_amount DESC
LIMIT 10;
