
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS purchase_count,
        MIN(d.d_date) AS first_purchase_date,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_id
),
Demographics AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status, 
        COUNT(cp.c_customer_id) AS customer_count,
        AVG(cp.total_sales) AS avg_sales,
        AVG(cp.purchase_count) AS avg_purchases
    FROM 
        CustomerPurchases cp
    JOIN 
        customer_demographics cd ON cp.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    d.customer_count,
    d.avg_sales,
    d.avg_purchases,
    w.w_warehouse_id,
    w.total_sales,
    w.total_orders
FROM 
    Demographics d
JOIN 
    WarehouseSales w ON 1=1
ORDER BY 
    d.cd_gender, d.cd_marital_status, w.total_sales DESC
LIMIT 100;
