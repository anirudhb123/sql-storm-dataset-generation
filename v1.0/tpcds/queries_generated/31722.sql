
WITH RECURSIVE CustomerReturns AS (
    SELECT c.c_customer_sk, c.c_customer_id, sr.returned_date, sr.return_quantity, sr.return_amt
    FROM customer c
    JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE sr.returned_date_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, c.c_customer_id, sr.returned_date, sr.return_quantity + cr.return_quantity, sr.return_amt + cr.return_amt
    FROM CustomerReturns cr
    JOIN customer c ON cr.c_customer_sk = c.c_customer_sk
    JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE sr.returned_date_sk IS NOT NULL AND sr.return_quantity > 0
),
SalesData AS (
    SELECT ws.ws_ship_date_sk, ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity_sold, SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_ship_date_sk, ws.ws_item_sk
),
ReturningCustomers AS (
    SELECT DISTINCT cr.c_customer_id
    FROM CustomerReturns cr
),
SalesWithReturns AS (
    SELECT sd.ws_ship_date_sk, sd.ws_item_sk, sd.total_quantity_sold, sd.total_net_profit,
           CASE 
               WHEN rc.c_customer_id IS NOT NULL THEN 'Returning'
               ELSE 'New'
           END AS customer_type
    FROM SalesData sd
    LEFT JOIN ReturningCustomers rc ON sd.ws_item_sk = rc.c_customer_id
),
FinalOutput AS (
    SELECT s.ws_ship_date_sk,
           s.ws_item_sk,
           s.total_quantity_sold,
           s.total_net_profit,
           ROW_NUMBER() OVER (PARTITION BY s.ws_item_sk ORDER BY s.total_net_profit DESC) AS profit_rank
    FROM SalesWithReturns s
    WHERE s.total_quantity_sold > 0
)
SELECT fo.ws_ship_date_sk, 
       fo.ws_item_sk, 
       fo.total_quantity_sold, 
       fo.total_net_profit, 
       fo.profit_rank
FROM FinalOutput fo
WHERE fo.profit_rank <= 5
ORDER BY fo.total_net_profit DESC;
