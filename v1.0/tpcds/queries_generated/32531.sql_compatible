
WITH RECURSIVE SalesHierarchy AS (
    SELECT ss_store_sk, SUM(ss_ext_sales_price) AS total_sales, 
           ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales 
    WHERE ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ss_store_sk
),
TopStores AS (
    SELECT sh.ss_store_sk, sh.total_sales
    FROM SalesHierarchy sh
    WHERE sh.sales_rank <= 5
),
CustomerReturns AS (
    SELECT sr_reason_sk, SUM(sr_return_quantity) AS total_returns,
           AVG(sr_return_amt_inc_tax) AS avg_return_amount
    FROM store_returns
    GROUP BY sr_reason_sk
),
ReturnReasons AS (
    SELECT r.r_reason_id, r.r_reason_desc, cr.total_returns, cr.avg_return_amount
    FROM CustomerReturns cr
    LEFT JOIN reason r ON cr.sr_reason_sk = r.r_reason_sk
),
FinalMetrics AS (
    SELECT ts.ss_store_sk, ts.total_sales, COALESCE(rr.total_returns, 0) AS total_returns,
           COALESCE(rr.avg_return_amount, 0) AS avg_return_amount
    FROM TopStores ts
    LEFT JOIN ReturnReasons rr ON ts.ss_store_sk = rr.r_reason_id
)
SELECT f.ss_store_sk, 
       f.total_sales, 
       f.total_returns, 
       f.avg_return_amount,
       CASE
           WHEN f.total_sales > 10000 THEN 'High Sales'
           WHEN f.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Sales'
           ELSE 'Low Sales'
       END AS sales_category,
       (SELECT COUNT(DISTINCT c.c_customer_id) 
        FROM customer c 
        WHERE c.c_current_addr_sk IS NOT NULL AND c.c_current_cdemo_sk IS NOT NULL) AS active_customers
FROM FinalMetrics f
ORDER BY f.total_sales DESC;
