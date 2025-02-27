
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_ext_sales_price) AS total_web_sales, 
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesMetrics AS (
    SELECT 
        c.c_customer_id,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.web_order_count,
        cs.catalog_order_count,
        (cs.total_web_sales + cs.total_catalog_sales) AS total_sales,
        CASE 
            WHEN cs.total_web_sales = 0 AND cs.total_catalog_sales = 0 THEN 'No Sales'
            WHEN cs.total_web_sales > cs.total_catalog_sales THEN 'More Web Sales'
            WHEN cs.total_web_sales < cs.total_catalog_sales THEN 'More Catalog Sales'
            ELSE 'Equal Sales'
        END AS sales_category
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    sm.c_customer_id,
    sm.total_sales,
    sm.web_order_count,
    sm.catalog_order_count,
    sm.sales_category,
    d.d_year,
    d.d_month_seq
FROM 
    SalesMetrics sm
JOIN 
    date_dim d ON d.d_date_sk IN (
        SELECT 
            DISTINCT ws.ws_sold_date_sk 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_bill_customer_sk IS NOT NULL
    )
WHERE 
    sm.total_sales > 1000
ORDER BY 
    sm.total_sales DESC, 
    sm.c_customer_id;
