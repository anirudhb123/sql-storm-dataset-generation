
WITH RecursiveSales AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
WithReturns AS (
    SELECT sr_item_sk, 
           COUNT(*) AS return_count, 
           SUM(sr_return_amt_inc_tax) AS total_returns
    FROM store_returns
    WHERE sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY sr_item_sk
)
SELECT ISNULL(i.i_item_desc, 'Unknown Item') AS item_description,
       COALESCE(RS.total_quantity, 0) AS total_web_sales_quantity,
       COALESCE(RS.total_sales, 0.00) AS total_web_sales_value,
       COALESCE(WR.return_count, 0) AS total_web_returns,
       COALESCE(WR.total_returns, 0.00) AS total_web_return_value,
       (COALESCE(RS.total_sales, 0) - COALESCE(WR.total_returns, 0)) AS net_sales_value,
       'Sales in ' + CAST(SUM(COALESCE(RS.total_sales, 0)) AS VARCHAR(50)) + ' & Returns in ' + 
       CAST(SUM(COALESCE(WR.total_returns, 0)) AS VARCHAR(50)) AS sales_and_returns_summary
FROM item i
LEFT JOIN RecursiveSales RS ON i.i_item_sk = RS.ws_item_sk
LEFT JOIN WithReturns WR ON i.i_item_sk = WR.sr_item_sk
WHERE (COALESCE(RS.total_sales, 0) > 1000 OR (COALESCE(WR.total_returns, 0) > 0 AND i.i_color IS NOT NULL))
GROUP BY i.i_item_sk, i.i_item_desc
HAVING SUM(COALESCE(RS.total_sales, 0)) BETWEEN 500 AND 10000
   OR COUNT(DISTINCT WR.return_count) >= 1
ORDER BY net_sales_value DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
