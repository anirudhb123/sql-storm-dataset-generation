
WITH RECURSIVE SalesData AS (
    SELECT 
        ss.sold_date_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        DENSE_RANK() OVER (ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales ss
    GROUP BY ss.sold_date_sk
),
CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_store_sk,
        SUM(sr_return_amt_inc_tax) AS total_returned,
        COUNT(sr_ticket_number) AS total_returns
    FROM store_returns
    WHERE sr_returned_date_sk IS NOT NULL
    GROUP BY sr_returned_date_sk, sr_store_sk
),
SalesAndReturns AS (
    SELECT 
        d.d_date AS sales_date,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(cr.total_returned, 0) AS total_returned,
        (COALESCE(sd.total_sales, 0) - COALESCE(cr.total_returned, 0)) AS net_sales
    FROM date_dim d
    LEFT JOIN SalesData sd ON d.d_date_sk = sd.sold_date_sk
    LEFT JOIN CustomerReturns cr ON d.d_date_sk = cr.returned_date_sk
    WHERE d.d_year = 2023
),
FinalResults AS (
    SELECT 
        sales_date,
        total_sales,
        total_returned,
        net_sales,
        RANK() OVER (ORDER BY net_sales DESC) AS net_sales_rank
    FROM SalesAndReturns
)
SELECT 
    f.sales_date,
    f.total_sales,
    f.total_returned,
    f.net_sales,
    f.net_sales_rank,
    CASE 
        WHEN f.net_sales_rank <= 10 THEN 'Top 10 Sales Days'
        ELSE 'Other Sales Days'
    END AS sales_category
FROM FinalResults f
WHERE f.net_sales > 0
ORDER BY f.net_sales DESC
LIMIT 20;
