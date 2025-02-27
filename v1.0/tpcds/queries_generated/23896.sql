
WITH RankedSales AS (
    SELECT ws_item_sk,
           SUM(ws_sales_price) AS total_sales,
           RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ws_item_sk
),
HighRankedItems AS (
    SELECT ir.ws_item_sk,
           i.i_item_desc,
           COALESCE(ic.ib_income_band_sk, 0) AS income_band,
           DENSE_RANK() OVER (ORDER BY ir.total_sales DESC) AS income_rank
    FROM RankedSales ir
    LEFT JOIN item i ON ir.ws_item_sk = i.i_item_sk
    LEFT JOIN household_demographics ic ON i.i_item_sk = ic.hd_demo_sk
    WHERE ir.sales_rank = 1
),
CustomerReturns AS (
    SELECT sr.returned_item_sk,
           COUNT(*) AS return_count,
           SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM store_returns sr
    WHERE sr.returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY sr.returned_item_sk
)
SELECT hi.ws_item_sk,
       hri.i_item_desc,
       hr.income_band,
       COALESCE(cr.return_count, 0) AS return_count,
       COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
       CASE 
           WHEN COALESCE(cr.return_count, 0) > 0 THEN 'Returned'
           ELSE 'Sold'
       END AS item_status
FROM HighRankedItems hr
LEFT JOIN CustomerReturns cr ON hr.ws_item_sk = cr.returned_item_sk
JOIN item i ON hr.ws_item_sk = i.i_item_sk
WHERE hr.income_rank < 5
ORDER BY hr.total_sales DESC, item_status DESC
FETCH FIRST 50 ROWS ONLY
UNION ALL 
SELECT NULL,
       'Aggregate Total',
       NULL,
       SUM(COALESCE(cr.return_count, 0)),
       SUM(COALESCE(cr.total_returned_amount, 0)),
       'Summary'
FROM CustomerReturns cr
WHERE cr.returned_item_sk IS NOT NULL
HAVING SUM(cr.total_returned_amount) > 1000.00;
