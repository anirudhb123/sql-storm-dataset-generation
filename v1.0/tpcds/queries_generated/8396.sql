
WITH ranked_sales AS (
    SELECT 
        w.warehouse_id,
        s.store_id,
        ws.web_site_id,
        SUM(cs_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY w.warehouse_id ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
    FROM 
        catalog_sales
    JOIN 
        warehouse w ON cs_warehouse_sk = w.w_warehouse_sk
    JOIN 
        store s ON cs_ship_mode_sk = s.s_store_sk
    JOIN 
        web_sales ws ON cs_order_number = ws.ws_order_number
    GROUP BY 
        w.warehouse_id, s.store_id, ws.web_site_id
),
top_sales AS (
    SELECT 
        warehouse_id, 
        store_id, 
        web_site_id, 
        total_sales
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 10
),
customer_summary AS (
    SELECT 
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ts.warehouse_id,
    ts.store_id,
    ts.web_site_id,
    ts.total_sales,
    cs.cd_gender,
    cs.total_profit
FROM 
    top_sales ts
LEFT JOIN 
    customer_summary cs ON ts.web_site_id = cs.web_site_id
ORDER BY 
    ts.total_sales DESC, cs.total_profit DESC;
