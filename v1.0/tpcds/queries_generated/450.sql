
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesSummary AS (
    SELECT 
        c.customer_name,
        c.total_web_sales,
        c.total_catalog_sales,
        c.total_store_sales,
        ROW_NUMBER() OVER (ORDER BY (c.total_web_sales + c.total_catalog_sales + c.total_store_sales) DESC) AS sales_rank
    FROM 
        (
            SELECT 
                CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
                cs.total_web_sales,
                cs.total_catalog_sales,
                cs.total_store_sales
            FROM 
                CustomerSales cs
        ) c
)
SELECT 
    customer_name,
    total_web_sales,
    total_catalog_sales,
    total_store_sales
FROM 
    SalesSummary
WHERE 
    sales_rank <= 10 OR total_web_sales > (SELECT AVG(total_web_sales) FROM CustomerSales)
ORDER BY 
    CASE WHEN total_web_sales > (SELECT AVG(total_web_sales) FROM CustomerSales) THEN 0 ELSE 1 END,
    total_web_sales DESC;
