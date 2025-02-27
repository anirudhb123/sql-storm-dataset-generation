
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           0 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesAggregates AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_sales_price) AS total_sales,
           COUNT(ws_order_number) AS order_count,
           AVG(ws_net_profit) AS average_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
ReturnStatistics AS (
    SELECT sr_customer_sk,
           COUNT(sr_ticket_number) AS return_count,
           SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_customer_sk
)
SELECT ch.c_customer_sk,
       ch.c_first_name,
       ch.c_last_name,
       COALESCE(sa.total_sales, 0) AS total_sales,
       COALESCE(sa.order_count, 0) AS order_count,
       COALESCE(rs.return_count, 0) AS return_count,
       COALESCE(rs.total_return_amount, 0) AS total_return_amount,
       CASE 
           WHEN COALESCE(sa.total_sales, 0) > 0 THEN ROUND((COALESCE(rs.total_return_amount, 0) / COALESCE(sa.total_sales, 1)) * 100, 2)
           ELSE 0 
       END AS return_percentage,
       ROW_NUMBER() OVER (PARTITION BY ch.level ORDER BY COALESCE(sa.total_sales, 0) DESC) AS sales_rank
FROM CustomerHierarchy ch
LEFT JOIN SalesAggregates sa ON ch.c_customer_sk = sa.ws_bill_customer_sk
LEFT JOIN ReturnStatistics rs ON ch.c_customer_sk = rs.sr_customer_sk
WHERE (sa.order_count > 5 OR rs.return_count > 0)
ORDER BY ch.c_last_name, ch.c_first_name;
