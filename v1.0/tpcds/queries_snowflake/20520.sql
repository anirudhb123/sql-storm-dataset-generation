
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_catalog_sales
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
), RankedSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        total_web_sales,
        total_catalog_sales,
        RANK() OVER (ORDER BY total_web_sales + total_catalog_sales DESC) AS sales_rank
    FROM 
        CustomerSales AS c
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        c_first_name,
        c_last_name,
        total_web_sales,
        total_catalog_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_web_sales, 0) AS web_sales,
    COALESCE(tc.total_catalog_sales, 0) AS catalog_sales,
    CASE 
        WHEN tc.total_web_sales > tc.total_catalog_sales THEN 'Web Dominant'
        WHEN tc.total_web_sales < tc.total_catalog_sales THEN 'Catalog Dominant'
        ELSE 'Equal Sales'
    END AS sales_category,
    (
        SELECT 
            COUNT(DISTINCT ws.ws_order_number)
        FROM 
            web_sales AS ws
        WHERE 
            ws.ws_bill_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id = tc.c_customer_id)
    ) AS unique_web_orders,
    (
        SELECT 
            COUNT(DISTINCT cs.cs_order_number)
        FROM 
            catalog_sales AS cs
        WHERE 
            cs.cs_bill_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id = tc.c_customer_id)
    ) AS unique_catalog_orders
FROM 
    TopCustomers AS tc
ORDER BY 
    tc.total_web_sales DESC NULLS LAST, 
    tc.total_catalog_sales DESC NULLS FIRST;
