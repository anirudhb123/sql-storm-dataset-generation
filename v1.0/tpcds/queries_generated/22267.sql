
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_sales_price * ws.ws_quantity), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_sales_price * cs.cs_quantity), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_sales_price * ss.ss_quantity), 0) AS total_store_sales,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_store_returns,
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_catalog_returns,
        COALESCE(SUM(wr.wr_return_amt), 0) AS total_web_returns
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_refunded_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerRanks AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        DENSE_RANK() OVER (ORDER BY total_web_sales DESC) AS web_sales_rank,
        DENSE_RANK() OVER (ORDER BY total_catalog_sales DESC) AS catalog_sales_rank,
        DENSE_RANK() OVER (ORDER BY total_store_sales DESC) AS store_sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    cr.*,
    CASE 
        WHEN cr.total_web_sales = 0 THEN 'No online purchases'
        ELSE 'Active online shopper'
    END AS online_shopper_status,
    COALESCE(NULLIF(cr.total_store_sales, 0), NULLIF(cr.total_catalog_sales, 0), NULLIF(cr.total_web_sales, 0), 'No sales recorded') AS sales_status,
    CASE 
        WHEN cr.web_sales_rank < 10 AND cr.catalog_sales_rank < 10 THEN 'Top Performer'
        ELSE 'Regular Performer'
    END AS performance_category
FROM 
    CustomerRanks cr
WHERE 
    (cr.total_web_sales + cr.total_catalog_sales + cr.total_store_sales) > (SELECT AVG(total_web_sales + total_catalog_sales + total_store_sales) FROM CustomerSales)
ORDER BY 
    cr.web_sales_rank, cr.catalog_sales_rank, cr.store_sales_rank;
