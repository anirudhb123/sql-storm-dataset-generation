
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022 AND 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_sk
)
SELECT 
    w.warehouse_id,
    w.warehouse_name,
    ss.web_site_sk,
    ss.total_sales,
    ss.total_orders,
    ss.total_profit,
    (ss.total_sales / NULLIF(ss.total_orders, 0)) AS avg_order_value
FROM 
    sales_summary ss
JOIN 
    warehouse w ON ss.web_site_sk = w.w_warehouse_sk
ORDER BY 
    total_sales DESC
LIMIT 10;
