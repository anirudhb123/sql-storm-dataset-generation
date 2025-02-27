
WITH sales_data AS (
    SELECT 
        w.w_warehouse_id, 
        s.s_store_id, 
        SUM(ws.ws_sales_price) AS total_sales, 
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
        d.d_year = 2023 AND 
        ws.ws_sales_price > 50.00
    GROUP BY 
        w.w_warehouse_id, 
        s.s_store_id
),
customer_data AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        SUM(ws.ws_sales_price) AS customer_total_spent
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id, 
        cd.cd_gender
)
SELECT 
    sd.w_warehouse_id, 
    sd.s_store_id, 
    AVG(cd.customer_total_spent) AS avg_customer_spending,
    SUM(sd.total_sales) AS warehouse_total_sales,
    SUM(sd.total_orders) AS warehouse_total_orders
FROM 
    sales_data sd 
JOIN 
    customer_data cd ON sd.w_warehouse_id = cd.c_customer_id
GROUP BY 
    sd.w_warehouse_id, 
    sd.s_store_id
ORDER BY 
    warehouse_total_sales DESC, 
    avg_customer_spending DESC;
