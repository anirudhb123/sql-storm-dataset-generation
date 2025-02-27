WITH CustomerReturns AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           SUM(sr_return_quantity) AS total_returns,
           SUM(sr_return_amt) AS total_return_amount
    FROM customer c
    JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(sr_return_quantity) > 0
), SalesData AS (
    SELECT s.s_store_sk,
           SUM(ws.ws_quantity) AS total_sales,
           SUM(ws.ws_sales_price) AS total_sales_amount
    FROM store s
    JOIN web_sales ws ON s.s_store_sk = ws.ws_ship_mode_sk 
    GROUP BY s.s_store_sk
), TopStores AS (
    SELECT s.s_store_sk, s.s_store_name, sd.total_sales, sd.total_sales_amount
    FROM store s
    JOIN SalesData sd ON s.s_store_sk = sd.s_store_sk
    ORDER BY sd.total_sales_amount DESC
    LIMIT 5
)
SELECT tr.c_first_name,
       tr.c_last_name,
       ts.s_store_name,
       tr.total_returns,
       tr.total_return_amount,
       ts.total_sales,
       ts.total_sales_amount
FROM CustomerReturns tr
JOIN TopStores ts ON tr.c_customer_sk IN (
    SELECT sr.sr_customer_sk
    FROM store_returns sr
    WHERE sr.sr_store_sk = ts.s_store_sk
)
ORDER BY tr.total_return_amount DESC, ts.total_sales_amount DESC;