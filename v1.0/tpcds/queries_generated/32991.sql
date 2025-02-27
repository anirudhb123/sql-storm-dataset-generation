
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 1 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_customer_sk
),
DailySales AS (
    SELECT d.d_date, 
           SUM(ws.ws_sales_price) AS total_sales_price,
           SUM(ws.ws_net_paid) AS total_net_paid,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_date
),
CustomerReturns AS (
    SELECT s.ss_customer_sk, 
           SUM(s.ss_ext_sales_price) AS total_returned_amount,
           COUNT(s.ss_ticket_number) AS total_returns
    FROM store_sales s
    LEFT JOIN store_returns sr ON s.ss_ticket_number = sr.sr_ticket_number
    GROUP BY s.ss_customer_sk
),
RankedCustomers AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           COALESCE(cr.total_returned_amount, 0) AS total_returned,
           COALESCE(cr.total_returns, 0) AS returns_count,
           CASE 
               WHEN COALESCE(cr.total_returned_amount, 0) > 0 THEN 'Returned'
               ELSE 'Active'
           END AS customer_status,
           ROW_NUMBER() OVER (PARTITION BY c.c_current_addr_sk ORDER BY COALESCE(cr.total_returned_amount, 0) DESC) AS rank
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.ss_customer_sk
)
SELECT r.c_customer_sk, 
       r.c_first_name, 
       r.c_last_name,
       r.total_returned, 
       r.returns_count, 
       dh.total_sales_price,
       dh.total_net_paid,
       dh.order_count,
       CASE 
           WHEN r.returns_count > 0 THEN 'Needs Attention' 
           ELSE 'All Good' 
       END AS customer_health,
       LEVEL AS customer_level
FROM RankedCustomers r
JOIN DailySales dh ON r.c_customer_sk = dh.d_date
WHERE r.rank <= 5
ORDER BY r.total_returned DESC, r.c_customer_sk;
