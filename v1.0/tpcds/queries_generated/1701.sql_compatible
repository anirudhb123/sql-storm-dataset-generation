
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
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
), RankedSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        ROW_NUMBER() OVER (PARTITION BY CASE 
            WHEN cs.total_web_sales > cs.total_catalog_sales AND cs.total_web_sales > cs.total_store_sales THEN 'Web'
            WHEN cs.total_catalog_sales > cs.total_web_sales AND cs.total_catalog_sales > cs.total_store_sales THEN 'Catalog'
            ELSE 'Store'
        END ORDER BY cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_web_sales,
    r.total_catalog_sales,
    r.total_store_sales,
    r.sales_rank,
    COALESCE(NOT EXISTS (
        SELECT 1
        FROM customer_demographics cd 
        WHERE cd.cd_demo_sk = r.c_customer_sk
        AND cd.cd_gender IS NULL
    ), 'No Data') AS gender_data,
    CASE
        WHEN r.total_web_sales > 5000 THEN 'High Value'
        WHEN r.total_web_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_category
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_web_sales DESC, 
    r.total_catalog_sales DESC, 
    r.total_store_sales DESC;
