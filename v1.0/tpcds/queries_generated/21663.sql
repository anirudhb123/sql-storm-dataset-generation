
WITH RankedSales AS (
    SELECT 
        ss.store_sk,
        ss.item_sk,
        ss_ext_sales_price,
        RANK() OVER (PARTITION BY ss.store_sk ORDER BY ss_ext_sales_price DESC) AS sales_rank
    FROM store_sales ss 
    WHERE ss.ss_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2022
    )
), 
CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk,
        COUNT(sr_returning_customer_sk) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns 
    GROUP BY sr_returning_customer_sk
), 
SalesSummary AS (
    SELECT 
        cs.bill_customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS order_count
    FROM catalog_sales cs 
    WHERE cs_sold_date_sk >= 2459647 -- Direct reference to a specific date
    GROUP BY cs.bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.total_sales,
    cs.order_count,
    cr.total_returns,
    cr.total_return_amount,
    COALESCE(rs.sales_rank, 0) AS sales_rank
FROM customer c
LEFT JOIN SalesSummary cs ON c.c_customer_sk = cs.bill_customer_sk
LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.returning_customer_sk
LEFT JOIN RankedSales rs ON rs.store_sk = 
    (SELECT MIN(s_store_sk) FROM store WHERE s_number_employees > 50 AND (s_state = 'CA' OR s_state IS NULL)) 
WHERE c.c_current_cdemo_sk IS NOT NULL
ORDER BY cs.total_sales DESC NULLS LAST, cr.total_return_amount ASC;
