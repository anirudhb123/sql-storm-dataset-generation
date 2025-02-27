
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
        SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        c.c_customer_id
),
SalesAnalytics AS (
    SELECT 
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        (total_web_sales + total_catalog_sales + total_store_sales) AS total_sales,
        web_order_count,
        catalog_order_count,
        store_order_count
    FROM 
        CustomerSales
)
SELECT 
    total_sales,
    AVG(total_sales) OVER () AS avg_sales,
    MAX(total_sales) OVER () AS max_sales,
    MIN(total_sales) OVER () AS min_sales,
    COUNT(*) AS customer_count
FROM 
    SalesAnalytics
WHERE 
    total_sales > (SELECT AVG(total_sales) FROM SalesAnalytics);
