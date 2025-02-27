
WITH RECURSIVE SalesHierarchy AS (
    SELECT ss_customer_sk, 
           SUM(ss_net_profit) AS total_profit,
           0 AS level
    FROM store_sales
    GROUP BY ss_customer_sk
    UNION ALL
    SELECT ss.ss_customer_sk, 
           SUM(ss.ss_net_profit) + sh.total_profit,
           sh.level + 1
    FROM store_sales ss
    JOIN SalesHierarchy sh ON ss.ss_customer_sk = sh.ss_customer_sk
    WHERE sh.level < 3
    GROUP BY ss.ss_customer_sk, sh.total_profit, sh.level
),
CustomerStats AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           SUM(COALESCE(ss.ss_net_profit, 0)) AS total_store_spent,
           COUNT(DISTINCT ss.ss_ticket_number) AS total_orders, 
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(COALESCE(ss.ss_net_profit, 0)) DESC) AS rank
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cs.total_store_spent, 
           cs.total_orders
    FROM CustomerStats cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_store_spent > (SELECT AVG(total_store_spent) FROM CustomerStats)
),
ReturningCustomers AS (
    SELECT wr.wr_returning_customer_sk,
           SUM(wr.wr_return_amt) AS total_return_amt,
           COUNT(wr.wr_return_quantity) AS total_return_count
    FROM web_returns wr
    GROUP BY wr.wr_returning_customer_sk
),
CustomerReturns AS (
    SELECT hc.c_customer_sk, 
           hc.c_first_name, 
           hc.c_last_name,
           COALESCE(SUM(rc.total_return_amt), 0) AS total_return_amt,
           COALESCE(COUNT(rc.total_return_count), 0) AS total_return_count 
    FROM HighValueCustomers hc
    LEFT JOIN ReturningCustomers rc ON hc.c_customer_sk = rc.wr_returning_customer_sk
    GROUP BY hc.c_customer_sk, hc.c_first_name, hc.c_last_name
)
SELECT ch.c_first_name, 
       ch.c_last_name,
       ch.total_store_spent,
       ch.total_orders,
       cr.total_return_amt,
       cr.total_return_count,
       sh.total_profit AS cumulative_profit
FROM HighValueCustomers ch
LEFT JOIN CustomerReturns cr ON ch.c_customer_sk = cr.c_customer_sk
LEFT JOIN SalesHierarchy sh ON ch.c_customer_sk = sh.ss_customer_sk
WHERE sh.level = 0 OR sh.total_profit > 1000
ORDER BY ch.total_store_spent DESC, cr.total_return_amt ASC;
