
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 
           c_current_cdemo_sk, 1 AS hierarchy_level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           c.c_current_cdemo_sk, ch.hierarchy_level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
DateInfo AS (
    SELECT d.d_date_sk, d.d_date, d.d_year, d.d_month_seq,
           ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY d.d_month_seq) AS month_rank
    FROM date_dim d
),
SalesSummary AS (
    SELECT ws.ws_bill_customer_sk AS customer_sk,
           SUM(ws.ws_net_paid) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN DateInfo di ON ws.ws_sold_date_sk = di.d_date_sk
    WHERE di.d_year = 2023
    GROUP BY ws.ws_bill_customer_sk
),
ReturnSummary AS (
    SELECT wr.wr_returning_customer_sk AS customer_sk,
           SUM(wr.wr_return_amt) AS total_returns,
           COUNT(*) AS return_count
    FROM web_returns wr
    JOIN DateInfo di ON wr.wr_returned_date_sk = di.d_date_sk
    WHERE di.d_year = 2023
    GROUP BY wr.wr_returning_customer_sk
),
FinalMetrics AS (
    SELECT cs.c_customer_sk,
           cs.c_first_name,
           cs.c_last_name,
           COALESCE(ss.total_sales, 0) AS total_sales,
           COALESCE(rs.total_returns, 0) AS total_returns,
           cs.hierarchy_level
    FROM CustomerHierarchy cs
    LEFT JOIN SalesSummary ss ON cs.c_customer_sk = ss.customer_sk
    LEFT JOIN ReturnSummary rs ON cs.c_customer_sk = rs.customer_sk
)
SELECT f.c_customer_sk,
       f.c_first_name,
       f.c_last_name,
       f.total_sales, 
       f.total_returns, 
       f.total_sales - f.total_returns AS net_spent,
       CASE 
           WHEN f.total_sales = 0 THEN NULL
           ELSE ROUND((f.total_returns / f.total_sales::numeric) * 100, 2)
       END AS return_percentage,
       RANK() OVER (ORDER BY f.total_sales DESC) AS sales_rank
FROM FinalMetrics f
WHERE f.total_sales > 5000
ORDER BY f.total_sales DESC
LIMIT 10;
