
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           c_current_cdemo_sk,
           1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_current_cdemo_sk,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesSummary AS (
    SELECT ws_bill_customer_sk AS customer_sk,
           SUM(ws_ext_sales_price) AS total_sales,
           COUNT(*) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
ReturnSummary AS (
    SELECT sr_customer_sk AS customer_sk,
           SUM(sr_return_amt) AS total_returns,
           COUNT(*) AS total_returns_count
    FROM store_returns
    GROUP BY sr_customer_sk
)

SELECT ch.c_first_name,
       ch.c_last_name,
       COALESCE(ss.total_sales, 0) AS total_sales,
       COALESCE(rs.total_returns, 0) AS total_returns,
       (COALESCE(ss.total_sales, 0) - COALESCE(rs.total_returns, 0)) AS net_sales,
       CASE
           WHEN COALESCE(ss.total_sales, 0) > 0 THEN (COALESCE(rs.total_returns, 0) * 100.0 / NULLIF(COALESCE(ss.total_sales, 0), 0))
           ELSE 0
       END AS return_rate,
       RANK() OVER (ORDER BY (COALESCE(ss.total_sales, 0) - COALESCE(rs.total_returns, 0)) DESC) AS sales_rank
FROM CustomerHierarchy ch
LEFT JOIN SalesSummary ss ON ch.c_customer_sk = ss.customer_sk
LEFT JOIN ReturnSummary rs ON ch.c_customer_sk = rs.customer_sk
WHERE ch.level = 1
AND (COALESCE(ss.total_sales, 0) > 1000 OR COALESCE(rs.total_returns, 0) > 200)
ORDER BY net_sales DESC, ch.c_last_name ASC;
