
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023
        AND cd.cd_marital_status = 'M'
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_sk
),
top_sales AS (
    SELECT 
        w.w_warehouse_id,
        w.w_warehouse_name,
        s.total_quantity,
        s.total_net_profit,
        s.avg_sales_price,
        ROW_NUMBER() OVER (ORDER BY s.total_net_profit DESC) AS rank
    FROM 
        sales_summary s
    JOIN 
        warehouse w ON s.web_site_sk = w.w_warehouse_sk
    WHERE 
        s.total_orders > 50
)
SELECT 
    ts.w_warehouse_id,
    ts.w_warehouse_name,
    ts.total_quantity,
    ts.total_net_profit,
    ts.avg_sales_price
FROM 
    top_sales ts
WHERE 
    ts.rank <= 10
ORDER BY 
    ts.total_net_profit DESC;
