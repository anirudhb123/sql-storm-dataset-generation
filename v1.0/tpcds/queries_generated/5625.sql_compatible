
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesByDemographics AS (
    SELECT 
        cd.cd_gender,
        SUM(cs.total_catalog_sales) AS total_catalog_sales_by_gender,
        SUM(cs.total_web_sales) AS total_web_sales_by_gender
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        store_sales ss
    JOIN 
        warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_name
),
FinalReport AS (
    SELECT 
        sd.cd_gender, 
        ws.w_warehouse_name, 
        sd.total_catalog_sales_by_gender, 
        sd.total_web_sales_by_gender, 
        ws.total_store_sales
    FROM 
        SalesByDemographics sd
    FULL OUTER JOIN 
        WarehouseSales ws ON sd.total_catalog_sales_by_gender = ws.total_store_sales
)

SELECT 
    fr.cd_gender,
    fr.w_warehouse_name,
    COALESCE(fr.total_catalog_sales_by_gender, 0) AS total_catalog_sales_by_gender,
    COALESCE(fr.total_web_sales_by_gender, 0) AS total_web_sales_by_gender,
    COALESCE(fr.total_store_sales, 0) AS total_store_sales
FROM 
    FinalReport fr
ORDER BY 
    fr.cd_gender, 
    fr.w_warehouse_name;
