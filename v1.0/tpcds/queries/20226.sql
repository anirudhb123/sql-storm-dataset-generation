
WITH RECURSIVE CustomerReturns AS (
    SELECT sr_customer_sk, COUNT(*) AS total_returns, SUM(sr_return_amt) AS total_return_amt
    FROM store_returns
    GROUP BY sr_customer_sk
), 
TopCustomers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cr.total_returns, cr.total_return_amt,
           RANK() OVER (ORDER BY cr.total_return_amt DESC) AS rank_return
    FROM customer c
    JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE cr.total_return_amt IS NOT NULL
),
ReturnReasons AS (
    SELECT sr_reason_sk, AVG(sr_return_amt) AS avg_return_amt
    FROM store_returns
    GROUP BY sr_reason_sk
    HAVING AVG(sr_return_amt) > 50
),
WebReturnsDetails AS (
    SELECT wr_returning_customer_sk, wr_item_sk, SUM(wr_return_quantity) AS total_return_quantity,
           SUM(wr_return_amt) AS total_return_amt,
           ROW_NUMBER() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_amt) DESC) AS item_rank
    FROM web_returns
    GROUP BY wr_returning_customer_sk, wr_item_sk
),
ItemDetails AS (
    SELECT i.i_item_sk, i.i_item_desc, i.i_category, SUM(ws_quantity) AS total_sold,
           SUM(ws_ext_sales_price) AS total_sales
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc, i.i_category
)
SELECT tc.c_first_name, tc.c_last_name, 
       id.i_item_desc, 
       id.total_sold, 
       id.total_sales, 
       cr.total_returns, 
       cr.total_return_amt,
       r.avg_return_amt,
       CASE 
           WHEN cr.total_returns > 10 THEN 'High Volume Returner' 
           WHEN cr.total_returns IS NULL THEN 'No Returns' 
           ELSE 'Average Returner' 
       END AS returner_type,
       CASE 
           WHEN wr.total_return_quantity IS NULL THEN 'Zero Return'
           ELSE 'Has Returns'
       END AS web_return_status
FROM TopCustomers tc
LEFT JOIN CustomerReturns cr ON tc.c_customer_sk = cr.sr_customer_sk
LEFT JOIN WebReturnsDetails wr ON wr.wr_returning_customer_sk = tc.c_customer_sk
LEFT JOIN ItemDetails id ON id.i_item_sk = wr.wr_item_sk
LEFT JOIN ReturnReasons r ON r.sr_reason_sk = (
    SELECT sr_reason_sk FROM store_returns sr 
    WHERE sr.sr_customer_sk = wr.wr_returning_customer_sk
    ORDER BY sr_return_amt DESC LIMIT 1
)
WHERE tc.rank_return <= 10
ORDER BY id.total_sales DESC, cr.total_return_amt ASC;
