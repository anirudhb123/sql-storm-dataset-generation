
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(ws.ws_order_number) AS web_order_count,
        COUNT(cs.cs_order_number) AS catalog_order_count,
        COUNT(ss.ss_ticket_number) AS store_order_count
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
), TotalSales AS (
    SELECT 
        c.c_customer_id,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) AS total_sales
    FROM 
        CustomerSales cs 
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    t.c_customer_id,
    t.total_web_sales,
    t.total_catalog_sales,
    t.total_store_sales,
    t.total_sales,
    d.d_year,
    d.d_month_seq,
    d.d_day_name
FROM 
    TotalSales t
JOIN 
    date_dim d ON (d.d_date_sk = (SELECT MAX(ws.ws_sold_date_sk) FROM web_sales ws WHERE ws.ws_bill_customer_sk = t.c_customer_id))
WHERE 
    t.total_sales > 10000
ORDER BY 
    t.total_sales DESC,
    t.c_customer_id
LIMIT 100;
