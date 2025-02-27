
WITH RECURSIVE TimeWindow AS (
    SELECT d_year, d_month_seq, d_week_seq, d_dow, d_date
    FROM date_dim
    WHERE d_date <= (SELECT MAX(d_date) FROM date_dim) - INTERVAL '1 year'
    UNION ALL
    SELECT d_year, d_month_seq, d_week_seq, d_dow, d_date
    FROM date_dim
    WHERE d_date > (SELECT MAX(d_date) FROM date_dim) - INTERVAL '1 year' AND d_year IN (SELECT MAX(d_year) FROM date_dim)
),
CustomerStats AS (
    SELECT 
        cd_gender,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        COUNT(DISTINCT c_current_addr_sk) AS unique_addresses,
        COUNT(DISTINCT c_customer_sk) AS total_customers
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender
),
RecentReturns AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(*) AS return_count,
        SUM(cr_return_amount) AS total_return_amt
    FROM catalog_returns
    WHERE cr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023) 
    GROUP BY cr_returning_customer_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS order_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    cs.cd_gender,
    cs.married_count,
    cs.unique_addresses,
    s.ws_bill_customer_sk,
    COALESCE(sr.return_count, 0) AS return_count,
    COALESCE(sr.total_return_amt, 0) AS total_return_amt,
    ss.total_sales,
    ss.total_orders
FROM CustomerStats cs
LEFT JOIN SalesSummary ss ON ss.ws_bill_customer_sk = cs.cd_demo_sk
LEFT JOIN RecentReturns sr ON sr.cr_returning_customer_sk = cs.cd_demo_sk
FULL OUTER JOIN TimeWindow tw ON tw.d_year BETWEEN 2019 AND 2023
WHERE (tw.d_month_seq BETWEEN 1 AND 12 OR cs.total_customers IS NULL)
  AND (ss.total_sales > 100 OR sr.total_return_amt IS NULL)
ORDER BY cs.cd_gender, total_sales DESC, return_count DESC
LIMIT 1000 OFFSET 100;
