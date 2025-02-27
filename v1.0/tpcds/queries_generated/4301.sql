
WITH RankedSales AS (
    SELECT ws_item_sk,
           SUM(ws_sales_price) AS total_sales,
           RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY ws_item_sk
),
TopSales AS (
    SELECT item.i_item_id,
           item.i_product_name,
           item.i_category,
           rs.total_sales
    FROM RankedSales rs
    JOIN item ON rs.ws_item_sk = item.i_item_sk
    WHERE rs.sales_rank <= 5
),
CustomerReturns AS (
    SELECT sr_item_sk,
           COUNT(DISTINCT sr_ticket_number) AS return_count,
           SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM store_returns
    GROUP BY sr_item_sk
),
FinalReport AS (
    SELECT ts.i_item_id,
           ts.i_product_name,
           ts.total_sales,
           COALESCE(cr.return_count, 0) AS return_count,
           COALESCE(cr.total_return_amt, 0) AS total_return_amt,
           (ts.total_sales - COALESCE(cr.total_return_amt, 0)) AS net_sales
    FROM TopSales ts
    LEFT JOIN CustomerReturns cr ON ts.i_item_id = cr.sr_item_sk
)
SELECT fr.i_item_id,
       fr.i_product_name,
       fr.total_sales,
       fr.return_count,
       fr.total_return_amt,
       fr.net_sales,
       CASE
           WHEN fr.net_sales > 1000 THEN 'High Performer'
           WHEN fr.net_sales BETWEEN 500 AND 1000 THEN 'Moderate Performer'
           ELSE 'Low Performer'
       END AS performance_category
FROM FinalReport fr
ORDER BY fr.total_sales DESC;
