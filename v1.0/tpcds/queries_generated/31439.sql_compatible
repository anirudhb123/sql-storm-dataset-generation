
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           0 AS level
    FROM customer c
    WHERE c.c_customer_sk IN (SELECT cd.cd_demo_sk 
                               FROM customer_demographics cd 
                               WHERE cd.cd_gender = 'F')
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           ch.level + 1
    FROM customer c
    INNER JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesSummary AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_sales_price) AS total_sales,
           COUNT(ws.ws_order_number) AS order_count,
           AVG(ws.ws_sales_price) AS avg_order_value
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
ReturnCounts AS (
    SELECT sr_customer_sk, COUNT(sr_ticket_number) AS total_returns
    FROM store_returns
    GROUP BY sr_customer_sk
),
FullCustomerData AS (
    SELECT ch.c_customer_sk, 
           ch.c_first_name, 
           ch.c_last_name, 
           ss.total_sales, 
           ss.order_count, 
           ss.avg_order_value,
           COALESCE(rc.total_returns, 0) AS total_returns
    FROM CustomerHierarchy ch
    LEFT JOIN SalesSummary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN ReturnCounts rc ON ch.c_customer_sk = rc.sr_customer_sk
)
SELECT c.c_first_name, c.c_last_name, 
       COALESCE(s.total_sales, 0) AS total_sales,
       COALESCE(s.order_count, 0) AS order_count,
       COALESCE(s.avg_order_value, 0) AS avg_order_value,
       s.total_returns,
       (COALESCE(s.total_sales, 0) - COALESCE(s.total_returns, 0)) AS net_sales_value
FROM FullCustomerData s
JOIN customer c ON s.c_customer_sk = c.c_customer_sk
WHERE (s.total_sales IS NOT NULL OR s.total_returns > 0)
  AND (s.total_returns < 5 OR s.avg_order_value > 100)
ORDER BY net_sales_value DESC
LIMIT 100;
