
WITH SalesData AS (
    SELECT 
        ws.warehouse_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        MAX(ws.ws_net_paid_inc_tax) AS max_net_paid
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    INNER JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.warehouse_sk
),
WarehouseData AS (
    SELECT 
        w.warehouse_id,
        w.warehouse_name,
        CASE 
            WHEN ws.total_sales > 1000000 THEN 'High Performer'
            WHEN ws.total_sales BETWEEN 500000 AND 1000000 THEN 'Moderate Performer'
            ELSE 'Low Performer'
        END AS performance_category,
        ws.total_sales,
        ws.total_orders,
        ws.avg_net_profit,
        ws.max_net_paid
    FROM 
        warehouse w
    INNER JOIN 
        SalesData ws ON w.warehouse_sk = ws.warehouse_sk
)
SELECT 
    wd.warehouse_id,
    wd.warehouse_name,
    wd.performance_category,
    wd.total_sales,
    wd.total_orders,
    wd.avg_net_profit,
    wd.max_net_paid
FROM 
    WarehouseData wd
ORDER BY 
    wd.total_sales DESC;
