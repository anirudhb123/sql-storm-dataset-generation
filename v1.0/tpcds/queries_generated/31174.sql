
WITH RECURSIVE SalesCTE AS (
    SELECT s_store_sk, 
           SUM(ss_net_paid) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2458432 AND 2458450
    GROUP BY s_store_sk
),
CustomerReturns AS (
    SELECT sr_store_sk,
           COUNT(sr_ticket_number) AS total_returns,
           SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_store_sk
),
AggregateSales AS (
    SELECT s.s_store_sk, 
           COALESCE(s.total_sales, 0) AS total_sales,
           COALESCE(r.total_returns, 0) AS total_returns,
           COALESCE(r.total_return_amount, 0) AS total_return_amount,
           (COALESCE(s.total_sales, 0) - COALESCE(r.total_return_amount, 0)) AS net_sales
    FROM SalesCTE s
    FULL OUTER JOIN CustomerReturns r ON s.s_store_sk = r.sr_store_sk
)
SELECT a.s_store_sk,
       a.total_sales,
       a.total_returns,
       a.total_return_amount,
       a.net_sales,
       d.d_date,
       d.d_month_seq,
       d.d_year,
       ROW_NUMBER() OVER (ORDER BY a.net_sales DESC) AS store_rank,
       CASE 
           WHEN a.net_sales > 50000 THEN 'High Performer'
           WHEN a.net_sales BETWEEN 20000 AND 50000 THEN 'Moderate Performer'
           ELSE 'Low Performer'
       END AS performance_category
FROM AggregateSales a
JOIN date_dim d ON d.d_date_sk = (
    SELECT MAX(d_date_sk) 
    FROM date_dim
    WHERE d_year BETWEEN 2021 AND 2023)
WHERE a.net_sales IS NOT NULL
ORDER BY a.net_sales DESC;

