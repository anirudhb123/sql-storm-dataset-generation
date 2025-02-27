
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id
),
StoreSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_sales_price) AS total_store_sales
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d.d_date_sk 
                                FROM date_dim d 
                                WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_id
),
SalesSummary AS (
    SELECT 
        cs.c_customer_id,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS grand_total_sales
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_id = ss.c_customer_id
)
SELECT 
    s.c_customer_id,
    s.total_web_sales,
    s.total_store_sales,
    s.grand_total_sales,
    DENSE_RANK() OVER (ORDER BY s.grand_total_sales DESC) AS sales_rank
FROM 
    SalesSummary s
WHERE 
    s.grand_total_sales > 1000
    AND NOT EXISTS (
        SELECT 1 FROM customer_demographics cd 
        WHERE cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk 
                               FROM customer c 
                               WHERE c.c_customer_id = s.c_customer_id)
        AND cd.cd_credit_rating = 'Fair'
    )
ORDER BY 
    sales_rank
LIMIT 10;
