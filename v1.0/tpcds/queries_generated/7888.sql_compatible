
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_sales_price, 0) + COALESCE(cs.cs_sales_price, 0) + COALESCE(ss.ss_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT CASE WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_order_number END) AS web_order_count,
        COUNT(DISTINCT CASE WHEN cs.cs_order_number IS NOT NULL THEN cs.cs_order_number END) AS catalog_order_count,
        COUNT(DISTINCT CASE WHEN ss.ss_ticket_number IS NOT NULL THEN ss.ss_ticket_number END) AS store_order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
DemographicAnalysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        AVG(cs.total_sales) AS avg_sales,
        SUM(cs.web_order_count) AS total_web_orders,
        SUM(cs.catalog_order_count) AS total_catalog_orders,
        SUM(cs.store_order_count) AS total_store_orders
    FROM CustomerSales cs
    JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
DateRangeSales AS (
    SELECT 
        d.d_date_id,
        SUM(COALESCE(ws.ws_sales_price, 0) + COALESCE(cs.cs_sales_price, 0) + COALESCE(ss.ss_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY d.d_date_id
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    da.cd_education_status,
    da.avg_sales,
    dr.total_sales AS annual_sales,
    dr.total_web_sales,
    dr.total_catalog_sales,
    dr.total_store_sales
FROM DemographicAnalysis da
JOIN DateRangeSales dr ON da.cd_gender = dr.total_sales
ORDER BY da.avg_sales DESC;
