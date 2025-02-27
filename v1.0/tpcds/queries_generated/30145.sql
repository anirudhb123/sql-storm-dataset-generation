
WITH RECURSIVE TotalSales AS (
    SELECT ss_item_sk, 
           SUM(ss_sales_price) AS total_sales,
           COUNT(ss_ticket_number) AS total_transactions,
           RANK() OVER (ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM store_sales
    GROUP BY ss_item_sk
),
HighValueItems AS (
    SELECT i.i_item_id, i.i_item_desc, ts.total_sales
    FROM item i
    JOIN TotalSales ts ON i.i_item_sk = ts.ss_item_sk
    WHERE ts.total_sales > 1000
),
CustomerReturns AS (
    SELECT sr_item_sk,
           SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    hvi.i_item_id,
    hvi.i_item_desc,
    hvi.total_sales,
    COALESCE(cr.total_returns, 0) AS total_returns,
    (hvi.total_sales - COALESCE(cr.total_returns, 0)) AS net_sales
FROM HighValueItems hvi
LEFT JOIN CustomerReturns cr ON hvi.hvi_item_id = cr.sr_item_sk
WHERE hvi.total_sales >= (
    SELECT AVG(total_sales) 
    FROM TotalSales 
    WHERE sales_rank <= 50
)
ORDER BY net_sales DESC
LIMIT 10;
