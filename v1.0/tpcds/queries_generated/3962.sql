
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        CUME_DIST() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_paid_inc_tax) AS total_store_sales
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
),
SalesComparison AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        ISNULL(ss.total_store_sales, 0) AS total_store_sales
    FROM 
        CustomerSales cs
    LEFT JOIN 
        (SELECT 
            s_store_sk, 
            SUM(ss_net_paid_inc_tax) AS total_store_sales
        FROM 
            store_sales
        GROUP BY 
            s_store_sk) ss ON cs.c_customer_sk = ss.s_store_sk
)
SELECT 
    sc.c_first_name,
    sc.c_last_name,
    sc.total_web_sales,
    sc.total_store_sales,
    (sc.total_web_sales - sc.total_store_sales) AS sales_difference,
    CASE 
        WHEN sc.total_web_sales > sc.total_store_sales THEN 'Web Dominant'
        WHEN sc.total_web_sales < sc.total_store_sales THEN 'Store Dominant'
        ELSE 'Equal'
    END AS sale_category,
    RANK() OVER (ORDER BY sales_difference DESC) AS sales_difference_rank
FROM 
    SalesComparison sc
WHERE 
    sc.total_web_sales IS NOT NULL
    AND sc.sales_rank <= 10;
