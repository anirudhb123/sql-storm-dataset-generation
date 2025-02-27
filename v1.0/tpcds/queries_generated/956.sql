
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales_count,
        MAX(ws.ws_sold_date_sk) AS last_web_sale_date,
        MAX(cs.cs_sold_date_sk) AS last_catalog_sale_date,
        MAX(ss.ss_sold_date_sk) AS last_store_sale_date
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
RecentSales AS (
    SELECT 
        cs.c_customer_id,
        GREATEST(cs.last_web_sale_date, cs.last_catalog_sale_date, cs.last_store_sale_date) AS last_sale_date,
        DATEDIFF(CURRENT_DATE, GREATEST(cs.last_web_sale_date, cs.last_catalog_sale_date, cs.last_store_sale_date)) AS days_since_last_sale
    FROM 
        CustomerSales cs
)
SELECT 
    c.c_customer_id,
    COALESCE(cs.total_web_sales, 0) AS total_web_sales,
    COALESCE(cs.total_catalog_sales, 0) AS total_catalog_sales,
    COALESCE(ss.total_store_sales_count, 0) AS total_store_sales_count,
    rs.last_sale_date,
    rs.days_since_last_sale
FROM 
    customer c
LEFT JOIN 
    CustomerSales cs ON c.c_customer_id = cs.c_customer_id
LEFT JOIN 
    RecentSales rs ON c.c_customer_id = rs.c_customer_id
WHERE 
    rs.days_since_last_sale < 30 OR rs.last_sale_date IS NULL
ORDER BY 
    total_web_sales DESC, total_catalog_sales DESC;
