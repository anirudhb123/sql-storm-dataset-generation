
WITH RECURSIVE SalesCTE AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_quantity, 
           SUM(ws_net_profit) AS total_profit,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM web_sales 
    WHERE ws_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY ws_item_sk
),
CustomerStats AS (
    SELECT c_customer_sk,
           SUM(ws_net_profit) AS total_customer_profit,
           COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c_customer_sk
),
TopCustomers AS (
    SELECT c.c_customer_id, 
           cs.total_customer_profit
    FROM CustomerStats cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_customer_profit > 5000
),
RecentReturns AS (
    SELECT sr_customer_sk, 
           COUNT(*) AS return_count,
           SUM(sr_return_amt) AS total_return_amt
    FROM store_returns 
    WHERE sr_returned_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY sr_customer_sk
),
FinalOutput AS (
    SELECT tc.c_customer_id, 
           tc.total_customer_profit, 
           COALESCE(rr.return_count, 0) AS return_count, 
           COALESCE(rr.total_return_amt, 0) AS total_return_amt,
           s.total_quantity,
           s.total_profit
    FROM TopCustomers tc
    LEFT JOIN RecentReturns rr ON tc.c_customer_id = rr.sr_customer_sk
    LEFT JOIN SalesCTE s ON s.ws_item_sk = (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = tc.c_customer_id LIMIT 1)
)
SELECT f.*, 
       CASE 
           WHEN f.return_count > 0 THEN 'Has Returns'
           ELSE 'No Returns'
       END AS return_status
FROM FinalOutput f
ORDER BY f.total_customer_profit DESC;
