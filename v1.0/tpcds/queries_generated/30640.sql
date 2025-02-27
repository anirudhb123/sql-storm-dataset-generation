
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 
           1 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    
    UNION ALL
    
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.c_current_cdemo_sk, 
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE c.c_customer_sk <> ch.c_customer_sk
),
SalesData AS (
    SELECT ws_bill_customer_sk AS customer_sk, 
           SUM(ws_sales_price) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
ReturnData AS (
    SELECT wr_returning_customer_sk AS customer_sk, 
           SUM(wr_return_amt_inc_tax) AS total_returns
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
FinalCustomerMetrics AS (
    SELECT ch.c_customer_sk, 
           CONCAT(ch.c_first_name, ' ', ch.c_last_name) AS full_name,
           COALESCE(sd.total_sales, 0) AS total_sales,
           COALESCE(rd.total_returns, 0) AS total_returns,
           (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_returns, 0)) AS net_sales
    FROM CustomerHierarchy ch
    LEFT JOIN SalesData sd ON ch.c_customer_sk = sd.customer_sk
    LEFT JOIN ReturnData rd ON ch.c_customer_sk = rd.customer_sk
)
SELECT fcm.*, 
       CASE 
           WHEN fcm.net_sales > 1000 THEN 'High Value Customer'
           WHEN fcm.net_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
           ELSE 'Low Value Customer'
       END AS customer_value
FROM FinalCustomerMetrics fcm
WHERE fcm.total_sales IS NOT NULL OR fcm.total_returns IS NOT NULL
ORDER BY fcm.net_sales DESC;
