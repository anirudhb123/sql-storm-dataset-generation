
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY 
        c.c_customer_id
),
DemographicsSummary AS (
    SELECT 
        cd.cd_gender,
        AVG(cs.total_sales) AS avg_sales,
        AVG(cs.total_orders) AS avg_orders,
        AVG(cs.avg_order_value) AS avg_order_value
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_paid) AS total_warehouse_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_warehouse_orders
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ds.cd_gender,
    ds.avg_sales,
    ds.avg_orders,
    ws.total_warehouse_sales,
    ws.total_warehouse_orders
FROM 
    DemographicsSummary ds
JOIN 
    WarehouseSales ws ON ws.total_warehouse_sales > 10000
ORDER BY 
    ds.avg_sales DESC;
