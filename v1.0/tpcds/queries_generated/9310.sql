
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        DATE(d.d_date) AS sales_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2023
        AND cd.cd_marital_status = 'M'
        AND cd.cd_gender = 'M'
    GROUP BY 
        ws.web_site_id, DATE(d.d_date)
),
warehouse_sales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS warehouse_total_sales
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    sd.web_site_id,
    sd.total_sales,
    sd.order_count,
    sd.avg_net_profit,
    ws.warehouse_total_sales,
    (sd.total_sales - ws.warehouse_total_sales) AS variance
FROM 
    sales_data sd
JOIN 
    warehouse_sales ws ON sd.web_site_id = ws.w_warehouse_id
ORDER BY 
    total_sales DESC
LIMIT 10;
