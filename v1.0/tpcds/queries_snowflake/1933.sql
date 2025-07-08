
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_store_returns,
        COALESCE(SUM(cr.cr_net_loss), 0) AS total_catalog_returns,
        COALESCE(SUM(wr.wr_net_loss), 0) AS total_web_returns
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
ranked_sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        cs.total_store_returns,
        cs.total_catalog_returns,
        cs.total_web_returns,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS web_sales_rank,
        RANK() OVER (ORDER BY cs.total_catalog_sales DESC) AS catalog_sales_rank,
        RANK() OVER (ORDER BY cs.total_store_sales DESC) AS store_sales_rank
    FROM customer_sales cs
)
SELECT 
    rs.c_customer_sk,
    rs.c_first_name,
    rs.c_last_name,
    rs.total_web_sales,
    rs.total_catalog_sales,
    rs.total_store_sales,
    rs.total_store_returns,
    rs.total_catalog_returns,
    rs.total_web_returns,
    CASE 
        WHEN rs.total_web_sales > 0 THEN 'Web Customer'
        WHEN rs.total_catalog_sales > 0 THEN 'Catalog Customer'
        WHEN rs.total_store_sales > 0 THEN 'Store Customer'
        ELSE 'No Sales'
    END AS customer_type,
    CASE 
        WHEN rs.total_store_returns > 0 OR rs.total_catalog_returns > 0 OR rs.total_web_returns > 0 
        THEN 'Has Returns' 
        ELSE 'No Returns' 
    END AS return_status
FROM ranked_sales rs
WHERE rs.web_sales_rank <= 10 OR rs.catalog_sales_rank <= 10 OR rs.store_sales_rank <= 10
ORDER BY rs.c_customer_sk;
