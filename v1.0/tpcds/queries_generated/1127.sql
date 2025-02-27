
WITH RankedCustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_ship_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
TopSales AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cs.order_count,
        cs.sales_rank
    FROM 
        RankedCustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.sales_rank <= 10
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS warehouse_sales
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_ship_date_sk = (SELECT MAX(ws2.ws_ship_date_sk) FROM web_sales ws2)
    GROUP BY 
        w.w_warehouse_id
),
CombinedSales AS (
    SELECT 
        ts.c_customer_id,
        ts.total_sales AS customer_sales,
        ws.warehouse_sales
    FROM 
        TopSales ts 
    LEFT JOIN 
        WarehouseSales ws ON ts.order_count = ws.warehouse_sales
)
SELECT 
    cs.c_customer_id,
    cs.customer_sales,
    COALESCE(ws.warehouse_sales, 0) AS warehouse_sales,
    (cs.customer_sales - COALESCE(ws.warehouse_sales, 0)) AS net_sales
FROM 
    CombinedSales cs
ORDER BY 
    net_sales DESC;
