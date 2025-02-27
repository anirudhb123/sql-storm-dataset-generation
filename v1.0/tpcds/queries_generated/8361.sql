
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
Demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
Returns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    sd.web_site_id,
    sd.total_sales,
    sd.total_orders,
    sd.avg_net_profit,
    sd.avg_net_paid,
    dm.cd_gender,
    dm.cd_marital_status,
    dm.cd_education_status,
    dm.customer_count,
    ws.w_warehouse_id,
    ws.total_orders AS warehouse_total_orders,
    ws.total_sales AS warehouse_total_sales,
    r.total_returns,
    r.total_return_amt
FROM 
    SalesData sd
JOIN 
    Demographics dm ON 1 = 1
JOIN 
    WarehouseSales ws ON 1 = 1
LEFT JOIN 
    Returns r ON r.sr_item_sk = ws.total_orders
ORDER BY 
    sd.total_sales DESC, dm.customer_count DESC;
