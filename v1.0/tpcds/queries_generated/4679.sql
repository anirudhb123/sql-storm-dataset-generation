
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_catalog_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_purchase_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_purchase_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_purchase_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
SalesRanking AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_store_sales,
        cs.total_web_sales,
        cs.total_catalog_sales,
        RANK() OVER (ORDER BY (cs.total_store_sales + cs.total_web_sales + cs.total_catalog_sales) DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    s.c_customer_id,
    s.c_first_name,
    s.c_last_name,
    s.total_store_sales,
    s.total_web_sales,
    s.total_catalog_sales,
    CASE 
        WHEN s.sales_rank <= 5 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    (SELECT 
        COUNT(DISTINCT wr_order_number)
     FROM 
        web_returns wr
     WHERE 
        wr_returning_customer_sk = s.c_customer_id) AS web_return_count,
    (SELECT 
        COUNT(DISTINCT sr_ticket_number)
     FROM 
        store_returns sr
     WHERE 
        sr_returning_customer_sk = s.c_customer_id) AS store_return_count
FROM 
    SalesRanking s
WHERE 
    (s.total_store_sales + s.total_web_sales + s.total_catalog_sales) > 1000
ORDER BY 
    s.sales_rank;
