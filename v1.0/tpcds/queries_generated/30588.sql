
WITH RECURSIVE CustomerReturns AS (
    SELECT wr_returning_customer_sk, 
           SUM(wr_return_quantity) AS total_returned_quantity,
           SUM(wr_return_amt_inc_tax) AS total_returned_amt
    FROM web_returns
    GROUP BY wr_returning_customer_sk
    
    UNION ALL
    
    SELECT sr_returning_customer_sk, 
           SUM(sr_return_quantity) AS total_returned_quantity,
           SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM store_returns
    WHERE sr_returning_customer_sk IS NOT NULL
    GROUP BY sr_returning_customer_sk
),
IncomeStats AS (
    SELECT hd_income_band_sk,
           COUNT(DISTINCT c_customer_sk) AS total_customers,
           AVG(cd_purchase_estimate) AS average_estimate
    FROM household_demographics hd
    LEFT JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY hd_income_band_sk
),
SalesSummary AS (
    SELECT date_dim.d_date,
           SUM(ws_ext_sales_price) AS total_web_sales,
           SUM(cs_ext_sales_price) AS total_catalog_sales,
           SUM(ss_ext_sales_price) AS total_store_sales
    FROM date_dim
    LEFT JOIN web_sales ws ON date_dim.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN catalog_sales cs ON date_dim.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN store_sales ss ON date_dim.d_date_sk = ss.ss_sold_date_sk
    GROUP BY date_dim.d_date
),
RankedReturns AS (
    SELECT cr.wr_returning_customer_sk,
           SUM(cr.wr_return_quantity) AS total_web_returned_quantity,
           SUM(cr.wr_return_amt_inc_tax) AS total_web_returned_amt,
           ROW_NUMBER() OVER (PARTITION BY cr.wr_returning_customer_sk ORDER BY SUM(cr.wr_return_amt_inc_tax) DESC) AS rank
    FROM web_returns cr
    GROUP BY cr.wr_returning_customer_sk 
)
SELECT coalesce(cs.c_first_name, '') AS customer_first_name,
       coalesce(cs.c_last_name, '') AS customer_last_name,
       is.total_customers,
       is.average_estimate,
       sr.total_web_sales,
       sr.total_catalog_sales,
       sr.total_store_sales,
       cr.total_returned_quantity,
       cr.total_returned_amt
FROM CustomerReturns cr
INNER JOIN IncomeStats is ON cr.wr_returning_customer_sk = is.hd_income_band_sk
INNER JOIN SalesSummary sr ON sr.total_web_sales = (SELECT SUM(total_web_sales) FROM SalesSummary)
LEFT JOIN customer cs ON cs.c_customer_sk = cr.wr_returning_customer_sk
WHERE cr.total_returned_amt IS NOT NULL
AND cr.total_returned_quantity > 1
ORDER BY cr.total_returned_amt DESC;
