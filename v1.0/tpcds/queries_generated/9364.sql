
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
AverageSales AS (
    SELECT 
        AVG(total_web_sales) AS avg_web_sales,
        AVG(total_catalog_sales) AS avg_catalog_sales,
        AVG(total_store_sales) AS avg_store_sales
    FROM 
        CustomerSales
),
SalesVariance AS (
    SELECT 
        c.c_customer_sk,
        ROW_NUMBER() OVER (ORDER BY total_web_sales DESC) AS web_sales_rank,
        ROW_NUMBER() OVER (ORDER BY total_catalog_sales DESC) AS catalog_sales_rank,
        ROW_NUMBER() OVER (ORDER BY total_store_sales DESC) AS store_sales_rank
    FROM 
        CustomerSales AS c
)
SELECT 
    AVG(web.sales_rank) AS average_web_sales_rank,
    AVG(catalog.sales_rank) AS average_catalog_sales_rank,
    AVG(store.sales_rank) AS average_store_sales_rank,
    avg.avg_web_sales,
    avg.avg_catalog_sales,
    avg.avg_store_sales
FROM 
    SalesVariance AS web
JOIN 
    SalesVariance AS catalog ON web.c_customer_sk = catalog.c_customer_sk
JOIN 
    SalesVariance AS store ON web.c_customer_sk = store.c_customer_sk
JOIN 
    AverageSales AS avg ON 1=1;
