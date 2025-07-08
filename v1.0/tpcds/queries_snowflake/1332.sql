
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_web_sales,
        SUM(cs.cs_sales_price) AS total_catalog_sales,
        SUM(ss.ss_sales_price) AS total_store_sales,
        COALESCE(SUM(ws.ws_sales_price), 0) + COALESCE(SUM(cs.cs_sales_price), 0) + COALESCE(SUM(ss.ss_sales_price), 0) AS total_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesRanking AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    sr.c_customer_sk,
    sr.c_first_name,
    sr.c_last_name,
    sr.total_web_sales,
    sr.total_catalog_sales,
    sr.total_store_sales,
    sr.sales_rank,
    LISTAGG(DISTINCT w.w_warehouse_name, ', ') WITHIN GROUP (ORDER BY w.w_warehouse_name) AS warehouses_used
FROM 
    SalesRanking sr
LEFT JOIN store s ON sr.total_store_sales > 0 AND s.s_store_sk = sr.c_customer_sk 
LEFT JOIN warehouse w ON s.s_store_sk = w.w_warehouse_sk
WHERE 
    sr.sales_rank <= 10
GROUP BY 
    sr.c_customer_sk, sr.c_first_name, sr.c_last_name, sr.total_web_sales, sr.total_catalog_sales, sr.total_store_sales, sr.sales_rank
ORDER BY 
    sr.sales_rank;
