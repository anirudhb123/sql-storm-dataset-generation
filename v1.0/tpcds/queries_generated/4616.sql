
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
        COUNT(DISTINCT sr.ticket_number) AS total_store_returns,
        COUNT(DISTINCT cr.order_number) AS total_catalog_returns
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_customer_id,
        cs.total_web_sales,
        cs.total_catalog_sales,
        CASE 
            WHEN (total_web_sales + total_catalog_sales) > 0 THEN 'Active'
            ELSE 'Inactive'
        END AS customer_status,
        RANK() OVER (ORDER BY (cs.total_web_sales + cs.total_catalog_sales) DESC) AS sales_rank
    FROM 
        CustomerSales cs 
),
TopCustomers AS (
    SELECT 
        customer_id,
        total_web_sales,
        total_catalog_sales,
        customer_status,
        sales_rank
    FROM 
        SalesSummary
    WHERE 
        sales_rank <= 10
)
SELECT
    tc.customer_id,
    tc.total_web_sales,
    tc.total_catalog_sales,
    tc.customer_status,
    tc.sales_rank,
    CASE 
        WHEN tc.total_web_sales IS NULL THEN 'No Web Sales'
        ELSE CONCAT('Web Sales Total: ', FORMAT(tc.total_web_sales, 2))
    END AS web_sales_summary,
    CASE 
        WHEN tc.total_catalog_sales IS NULL THEN 'No Catalog Sales'
        ELSE CONCAT('Catalog Sales Total: ', FORMAT(tc.total_catalog_sales, 2))
    END AS catalog_sales_summary
FROM 
    TopCustomers tc
ORDER BY 
    tc.sales_rank;
