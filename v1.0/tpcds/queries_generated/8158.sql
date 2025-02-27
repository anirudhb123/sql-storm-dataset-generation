
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.ws_sold_date_sk
),
CustomerData AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.ws_ext_sales_price) AS warehouse_sales
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
),
DailySales AS (
    SELECT 
        d.d_date_id,
        SUM(ws.ws_ext_sales_price) AS daily_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date_id
)
SELECT 
    d.d_date_id,
    sd.total_quantity,
    sd.total_sales,
    cd.customer_count,
    cd.avg_purchase_estimate,
    ws.warehouse_sales,
    ds.daily_sales
FROM 
    date_dim d
LEFT JOIN 
    SalesData sd ON d.d_date_sk = sd.ws_sold_date_sk
LEFT JOIN 
    CustomerData cd ON cd.cd_demo_sk IN (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_first_shipto_date_sk = d.d_date_sk)
LEFT JOIN 
    WarehouseSales ws ON ws.w_warehouse_sk IN (SELECT ws.ws_warehouse_sk FROM web_sales ws WHERE ws.ws_sold_date_sk = d.d_date_sk)
LEFT JOIN 
    DailySales ds ON ds.d_date_id = d.d_date_id
WHERE 
    d.d_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
ORDER BY 
    d.d_date_id;
