
WITH RankedSales AS (
    SELECT s.s_store_sk, 
           s.s_store_name, 
           ws.ws_sold_date_sk, 
           SUM(ws.ws_sales_price) AS total_sales,
           DENSE_RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM store s
    JOIN web_sales ws ON s.s_store_sk = ws.ws_store_sk
    GROUP BY s.s_store_sk, s.s_store_name, ws.ws_sold_date_sk
), RecentReturns AS (
    SELECT sr_store_sk, 
           COUNT(sr_ticket_number) AS total_returns,
           SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_store_sk
), StoreMetrics AS (
    SELECT r.s_store_sk,
           r.s_store_name,
           COALESCE(s.total_sales, 0) AS total_sales,
           COALESCE(c.total_returns, 0) AS total_returns,
           COALESCE(c.total_return_amount, 0) AS total_return_amount,
           COALESCE(s.total_sales, 0) - COALESCE(c.total_return_amount, 0) AS net_sales
    FROM store r
    LEFT JOIN RankedSales s ON r.s_store_sk = s.s_store_sk
    LEFT JOIN RecentReturns c ON r.s_store_sk = c.s_store_sk
)
SELECT sm.s_store_name,
       sm.total_sales,
       sm.total_returns,
       sm.total_return_amount,
       sm.net_sales,
       (CASE WHEN sm.total_returns > 0 THEN (sm.total_return_amount / sm.total_returns) ELSE NULL END) AS avg_return_amount
FROM StoreMetrics sm
WHERE sm.total_sales > 10000
ORDER BY sm.net_sales DESC;
