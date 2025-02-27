
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        coalesce(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        coalesce(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
        coalesce(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY coalesce(SUM(ws.ws_net_paid), 0) DESC) AS web_sales_rank,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY coalesce(SUM(cs.cs_net_paid), 0) DESC) AS catalog_sales_rank,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY coalesce(SUM(ss.ss_net_paid), 0) DESC) AS store_sales_rank
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
RankedSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        cs.web_sales_rank,
        cs.catalog_sales_rank,
        cs.store_sales_rank
    FROM 
        CustomerSales cs
    INNER JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_web_sales > (SELECT AVG(total_web_sales) FROM CustomerSales)
        OR cs.total_catalog_sales > (SELECT AVG(total_catalog_sales) FROM CustomerSales)
        OR cs.total_store_sales > (SELECT AVG(total_store_sales) FROM CustomerSales)
)
SELECT 
    customer_sk, 
    c_first_name, 
    c_last_name, 
    total_web_sales, 
    total_catalog_sales, 
    total_store_sales,
    CASE 
        WHEN total_web_sales > total_catalog_sales AND total_web_sales > total_store_sales THEN 'Web'
        WHEN total_catalog_sales > total_web_sales AND total_catalog_sales > total_store_sales THEN 'Catalog'
        ELSE 'Store'
    END AS top_channel
FROM 
    RankedSales
ORDER BY 
    total_web_sales DESC, total_catalog_sales DESC, total_store_sales DESC
FETCH FIRST 10 ROWS ONLY;
